#!/usr/bin/env bash
# =============================================================================
# HC TECH AI SYSTEM — Inicializador Completo
# Substitui: iniciar_completo.bat / iniciar.ps1
# =============================================================================

set -uo pipefail

# ─── Configuração ─────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"
PID_DIR="$PROJECT_DIR/.pids"
LOG_DIR="$PROJECT_DIR/logs"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Helpers ──────────────────────────────────────────────────────────────────
log()  { echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} $*"; }
ok()   { echo -e "${GREEN}[$(date '+%H:%M:%S')] ✓${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠${NC}  $*"; }
erro() { echo -e "${RED}[$(date '+%H:%M:%S')] ✗${NC} $*"; }

banner() {
    clear
    echo -e "${BOLD}${BLUE}"
    cat << 'EOF'
  ┌─────────────────────────────────────────────────┐
  │         HC TECH AI SYSTEM  v2.1                 │
  │         CachyOS / Arch Linux Edition            │
  │                                                  │
  │   🧭 HC-CEO   🔍 HC-SEO   📱 HC-SOCIAL          │
  │   ✍️  HC-CONTENT   💻 HC-CODE                   │
  └─────────────────────────────────────────────────┘
EOF
    echo -e "${NC}"
}

# ─── Criar diretórios ─────────────────────────────────────────────────────────
mkdir -p "$PID_DIR" "$LOG_DIR"

# ─── Salvar PID ───────────────────────────────────────────────────────────────
save_pid() {
    local name="$1"
    local pid="$2"
    echo "$pid" > "$PID_DIR/$name.pid"
}

# ─── Verificar porta em uso ───────────────────────────────────────────────────
port_in_use() {
    local port="$1"
    ss -tlnp 2>/dev/null | grep -q ":${port}" || \
    lsof -ti ":${port}" &>/dev/null
}

# ─── Matar processo em porta ─────────────────────────────────────────────────
kill_port() {
    local port="$1"
    local pids
    pids=$(lsof -ti ":${port}" 2>/dev/null || true)
    if [[ -n "$pids" ]]; then
        warn "Encerrando processo na porta $port (PID: $pids)..."
        kill -TERM $pids 2>/dev/null || true
        sleep 1
    fi
}

# ─── Aguardar serviço subir ───────────────────────────────────────────────────
wait_for_service() {
    local name="$1"
    local url="$2"
    local max_wait="${3:-30}"
    local i=0

    log "Aguardando $name em $url..."
    while ! curl -sf "$url" &>/dev/null; do
        ((i++))
        if [[ $i -ge $max_wait ]]; then
            warn "$name não respondeu em ${max_wait}s. Continuando mesmo assim..."
            return 1
        fi
        printf "."
        sleep 1
    done
    echo ""
    ok "$name está respondendo! (${i}s)"
    return 0
}

# ─── 1. Iniciar Ollama ────────────────────────────────────────────────────────
start_ollama() {
    log "━━━ [1/3] Verificando Ollama ━━━"

    if ! command -v ollama &>/dev/null; then
        warn "Ollama não instalado. Pulando IA local."
        return 0
    fi

    if curl -sf http://localhost:11434/api/tags &>/dev/null; then
        ok "Ollama já está rodando."
        return 0
    fi

    # Tentar via systemd primeiro
    if systemctl is-active --quiet ollama.service 2>/dev/null; then
        ok "Ollama via systemd está ativo."
        return 0
    fi

    log "Iniciando ollama serve..."
    nohup ollama serve > "$LOG_DIR/ollama.log" 2>&1 &
    save_pid "ollama" $!
    ok "Ollama iniciado (PID: $!)"

    wait_for_service "Ollama" "http://localhost:11434/api/tags" 20 || true
}

# ─── 2. Iniciar Backend ───────────────────────────────────────────────────────
start_backend() {
    log "━━━ [2/3] Iniciando Backend (FastAPI) ━━━"

    if [[ ! -d "$BACKEND_DIR" ]]; then
        erro "Diretório backend/ não encontrado: $BACKEND_DIR"
        return 1
    fi

    if port_in_use 8000; then
        warn "Porta 8000 já em uso."
        read -rp "Encerrar processo existente? [s/N]: " kill_existing
        if [[ "${kill_existing,,}" == "s" ]]; then
            kill_port 8000
            sleep 1
        else
            ok "Reutilizando backend existente."
            return 0
        fi
    fi

    if [[ ! -f "$BACKEND_DIR/.venv/bin/activate" ]]; then
        erro "virtualenv não encontrado. Execute o instalador primeiro."
        return 1
    fi

    if [[ ! -f "$BACKEND_DIR/.env" ]]; then
        erro ".env não encontrado em $BACKEND_DIR"
        erro "Copie .env.example para .env e configure."
        return 1
    fi

    log "Iniciando uvicorn..."
    (
        cd "$BACKEND_DIR"
        source .venv/bin/activate
        nohup uvicorn app.main:app \
            --host 0.0.0.0 \
            --port 8000 \
            --reload \
            --log-level info \
            > "$LOG_DIR/backend.log" 2>&1 &
        save_pid "backend" $!
        ok "Backend iniciado (PID: $!)"
    )

    wait_for_service "Backend" "http://localhost:8000/health" 30
}

# ─── 3. Iniciar Frontend ──────────────────────────────────────────────────────
start_frontend() {
    log "━━━ [3/3] Iniciando Frontend (Next.js) ━━━"

    if [[ ! -d "$FRONTEND_DIR" ]]; then
        erro "Diretório frontend/ não encontrado: $FRONTEND_DIR"
        return 1
    fi

    if port_in_use 3000; then
        warn "Porta 3000 já em uso."
        read -rp "Encerrar processo existente? [s/N]: " kill_existing
        if [[ "${kill_existing,,}" == "s" ]]; then
            kill_port 3000
            sleep 1
        else
            ok "Reutilizando frontend existente."
            return 0
        fi
    fi

    if [[ ! -d "$FRONTEND_DIR/node_modules" ]]; then
        warn "node_modules não encontrado. Instalando..."
        (cd "$FRONTEND_DIR" && npm install)
    fi

    log "Iniciando Next.js dev server..."
    (
        cd "$FRONTEND_DIR"
        nohup npm run dev \
            > "$LOG_DIR/frontend.log" 2>&1 &
        save_pid "frontend" $!
        ok "Frontend iniciado (PID: $!)"
    )

    wait_for_service "Frontend" "http://localhost:3000" 45
}

# ─── Abrir navegador ──────────────────────────────────────────────────────────
open_browser() {
    log "Abrindo navegador..."
    sleep 2

    local url="http://localhost:3000"

    # Tentar diferentes métodos
    if command -v xdg-open &>/dev/null; then
        xdg-open "$url" &>/dev/null &
    elif command -v firefox &>/dev/null; then
        firefox "$url" &>/dev/null &
    elif command -v chromium &>/dev/null; then
        chromium "$url" &>/dev/null &
    elif command -v google-chrome-stable &>/dev/null; then
        google-chrome-stable "$url" &>/dev/null &
    else
        warn "Não foi possível abrir o navegador automaticamente."
        log "Acesse manualmente: $url"
    fi
}

# ─── Status dos serviços ──────────────────────────────────────────────────────
show_status() {
    echo ""
    echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}  ✅ HC TECH AI SYSTEM — ONLINE                  ${NC}"
    echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════${NC}"
    echo ""

    local services=(
        "Ollama:11434:🤖 IA Local"
        "Backend:8000:⚡ FastAPI"
        "Frontend:3000:🌐 Interface"
    )

    for svc in "${services[@]}"; do
        IFS=: read -r name port label <<< "$svc"
        if curl -sf "http://localhost:${port}" &>/dev/null || \
           curl -sf "http://localhost:${port}/api/tags" &>/dev/null || \
           curl -sf "http://localhost:${port}/health" &>/dev/null || \
           port_in_use "$port"; then
            echo -e "  ${GREEN}●${NC} $label → http://localhost:${port}"
        else
            echo -e "  ${RED}●${NC} $label → OFFLINE"
        fi
    done

    echo ""
    echo -e "  ${CYAN}📖 API Docs:${NC}  http://localhost:8000/docs"
    echo -e "  ${CYAN}📋 Logs:${NC}      $LOG_DIR/"
    echo -e "  ${CYAN}🛑 Parar:${NC}     ./scripts/parar.sh"
    echo ""
    echo -e "${BOLD}Pressione Ctrl+C para encerrar todos os serviços.${NC}"
    echo ""
}

# ─── Handler de saída ─────────────────────────────────────────────────────────
cleanup() {
    echo ""
    log "Encerrando HC Tech AI System..."

    for pid_file in "$PID_DIR"/*.pid; do
        if [[ -f "$pid_file" ]]; then
            local pid
            pid=$(cat "$pid_file")
            local name
            name=$(basename "$pid_file" .pid)

            if kill -0 "$pid" 2>/dev/null; then
                log "Encerrando $name (PID: $pid)..."
                kill -TERM "$pid" 2>/dev/null || true
            fi
            rm -f "$pid_file"
        fi
    done

    # Matar processos nas portas por garantia
    kill_port 8000 2>/dev/null || true
    kill_port 3000 2>/dev/null || true

    ok "Sistema encerrado."
    exit 0
}

trap cleanup INT TERM EXIT

# ─── MAIN ─────────────────────────────────────────────────────────────────────
main() {
    banner

    # Verificar se está no diretório correto
    if [[ ! -f "$PROJECT_DIR/README.md" ]] && \
       [[ ! -d "$PROJECT_DIR/backend" ]]; then
        erro "Execute este script na raiz do projeto HCTech_AI-System."
        exit 1
    fi

    start_ollama
    start_backend
    start_frontend
    open_browser
    show_status

    # Manter script vivo e mostrar logs
    log "Sistema rodando. Pressione Ctrl+C para encerrar."
    echo ""

    # Tail dos logs em paralelo (opcional)
    if command -v tail &>/dev/null; then
        tail -f "$LOG_DIR/backend.log" "$LOG_DIR/frontend.log" 2>/dev/null &
        local tail_pid=$!

        # Aguardar sinal
        wait

        kill "$tail_pid" 2>/dev/null || true
    else
        wait
    fi
}

main "$@"
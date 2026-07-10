#!/usr/bin/env bash
# =============================================================================
# HC TECH AI SYSTEM — Instalador para CachyOS / Arch Linux
# v2.1 | Substitui: Instalar-HCTechAI.ps1 / .bat
# =============================================================================

set -euo pipefail

# ─── Cores ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ─── Variáveis globais ────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/tmp/hctech-install-$(date +%Y%m%d-%H%M%S).log"
PYTHON_MIN="3.11"
NODE_MIN="18"

# ─── Helpers ─────────────────────────────────────────────────────────────────
log()     { echo -e "${CYAN}[INFO]${NC}  $*" | tee -a "$LOG_FILE"; }
ok()      { echo -e "${GREEN}[OK]${NC}    $*" | tee -a "$LOG_FILE"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*" | tee -a "$LOG_FILE"; }
erro()    { echo -e "${RED}[ERRO]${NC}  $*" | tee -a "$LOG_FILE"; }
titulo()  { echo -e "\n${BOLD}${BLUE}══════════════════════════════════════${NC}"; \
             echo -e "${BOLD}${BLUE}  $*${NC}"; \
             echo -e "${BOLD}${BLUE}══════════════════════════════════════${NC}\n"; }

banner() {
cat << 'EOF'

  ██╗  ██╗ ██████╗    ████████╗███████╗ ██████╗██╗  ██╗
  ██║  ██║██╔════╝       ██╔══╝██╔════╝██╔════╝██║  ██║
  ███████║██║            ██║   █████╗  ██║     ███████║
  ██╔══██║██║            ██║   ██╔══╝  ██║     ██╔══██║
  ██║  ██║╚██████╗       ██║   ███████╗╚██████╗██║  ██║
  ╚═╝  ╚═╝ ╚═════╝       ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝

       AI SYSTEM v2.1 — Instalador CachyOS/Arch Linux
       HC Tech InfoCell | São Bernardo do Campo/SP

EOF
}

# ─── Verificações iniciais ────────────────────────────────────────────────────
check_root() {
    if [[ $EUID -eq 0 ]]; then
        erro "Não execute como root! Use seu usuário normal."
        erro "O script pedirá sudo quando necessário."
        exit 1
    fi
}

check_arch() {
    if ! command -v pacman &>/dev/null; then
        erro "Este instalador requer Arch Linux / CachyOS (pacman não encontrado)."
        exit 1
    fi
    ok "Sistema Arch/CachyOS detectado."
}

check_internet() {
    log "Verificando conexão com a internet..."
    if ! ping -c 1 8.8.8.8 &>/dev/null && ! ping -c 1 1.1.1.1 &>/dev/null; then
        erro "Sem conexão com a internet. Verifique sua rede."
        exit 1
    fi
    ok "Internet OK."
}

# ─── Instalar AUR helper ──────────────────────────────────────────────────────
install_yay() {
    if command -v yay &>/dev/null; then
        ok "yay já instalado: $(yay --version | head -1)"
        return 0
    fi

    log "Instalando yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm git base-devel 2>>"$LOG_FILE"

    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay" 2>>"$LOG_FILE"
    (cd "$tmp_dir/yay" && makepkg -si --noconfirm 2>>"$LOG_FILE")
    rm -rf "$tmp_dir"

    ok "yay instalado com sucesso."
}

# ─── Instalar dependências do sistema ─────────────────────────────────────────
install_system_deps() {
    titulo "Instalando dependências do sistema"

    local pacman_pkgs=(
        git
        base-devel
        python
        python-pip
        python-virtualenv
        nodejs
        npm
        curl
        wget
        jq
        sqlite
        openssl
        ca-certificates
        xdg-utils          # para abrir browser
        xdotool            # automação de janelas (opcional)
    )

    log "Atualizando base de dados do pacman..."
    sudo pacman -Sy --noconfirm 2>>"$LOG_FILE"

    log "Instalando pacotes via pacman: ${pacman_pkgs[*]}"
    sudo pacman -S --needed --noconfirm "${pacman_pkgs[@]}" 2>>"$LOG_FILE"

    # Verificar versão do Python
    local py_version
    py_version=$(python --version 2>&1 | grep -oP '\d+\.\d+')
    log "Python encontrado: $py_version"

    # Verificar versão do Node
    local node_version
    node_version=$(node --version | tr -d 'v' | cut -d. -f1)
    if [[ "$node_version" -lt "$NODE_MIN" ]]; then
        warn "Node.js $node_version encontrado. Recomendado: >= $NODE_MIN"
        warn "Instalando versão mais recente via nvm..."
        install_nvm
    else
        ok "Node.js $(node --version) OK."
    fi

    ok "Dependências do sistema instaladas."
}

# ─── NVM (opcional, para Node LTS) ───────────────────────────────────────────
install_nvm() {
    if [[ -d "$HOME/.nvm" ]]; then
        ok "nvm já instalado."
        return 0
    fi

    log "Instalando nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # Carrega nvm imediatamente
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

    nvm install --lts
    nvm use --lts

    ok "nvm + Node.js LTS instalados."
}

# ─── Instalar Ollama ──────────────────────────────────────────────────────────
install_ollama() {
    titulo "Instalando Ollama (IA Local)"

    if command -v ollama &>/dev/null; then
        ok "Ollama já instalado: $(ollama --version 2>/dev/null || echo 'versão desconhecida')"
    else
        log "Baixando e instalando Ollama..."

        # Método 1: Script oficial
        if curl -fsSL https://ollama.com/install.sh | sh 2>>"$LOG_FILE"; then
            ok "Ollama instalado via script oficial."
        else
            # Método 2: AUR
            warn "Script oficial falhou. Tentando via AUR..."
            yay -S --noconfirm ollama 2>>"$LOG_FILE" || {
                erro "Falha ao instalar Ollama."
                return 1
            }
        fi
    fi

    # Habilitar serviço systemd do Ollama
    if systemctl list-unit-files | grep -q "ollama.service"; then
        log "Habilitando serviço ollama..."
        sudo systemctl enable --now ollama.service 2>>"$LOG_FILE" || true
        ok "Serviço ollama ativo."
    else
        warn "Serviço systemd do ollama não encontrado. Use 'ollama serve' manualmente."
    fi

    # Baixar modelo padrão
    pull_ollama_models
}

pull_ollama_models() {
    log "Aguardando Ollama iniciar..."
    local retries=10
    local i=0

    # Garante que o ollama está rodando
    if ! pgrep -x ollama &>/dev/null; then
        log "Iniciando ollama serve em background..."
        ollama serve &>/tmp/ollama.log &
        sleep 3
    fi

    while ! curl -sf http://localhost:11434/api/tags &>/dev/null; do
        ((i++))
        if [[ $i -ge $retries ]]; then
            warn "Ollama não respondeu. Pule o download do modelo por agora."
            return 0
        fi
        sleep 2
    done

    ok "Ollama está respondendo."

    # Modelos recomendados (do menor para o maior)
    local models=("llama3.2:3b" "llama3.1:8b")

    echo ""
    echo -e "${YELLOW}Escolha o modelo Ollama para baixar:${NC}"
    echo "  1) llama3.2:3b   (~2GB) — mais leve, rápido"
    echo "  2) llama3.1:8b   (~5GB) — mais capaz"
    echo "  3) Nenhum agora  — baixar depois"
    echo ""
    read -rp "Opção [1]: " model_choice
    model_choice="${model_choice:-1}"

    case "$model_choice" in
        1)
            log "Baixando llama3.2:3b (pode demorar)..."
            ollama pull llama3.2:3b 2>>"$LOG_FILE" && ok "Modelo llama3.2:3b baixado." || warn "Falha no download."
            ;;
        2)
            log "Baixando llama3.1:8b (pode demorar bastante)..."
            ollama pull llama3.1:8b 2>>"$LOG_FILE" && ok "Modelo llama3.1:8b baixado." || warn "Falha no download."
            ;;
        3)
            warn "Pulando download. Lembre-se de executar: ollama pull llama3.2:3b"
            ;;
        *)
            warn "Opção inválida. Pulando."
            ;;
    esac
}

# ─── Clonar / atualizar repositório ──────────────────────────────────────────
setup_repo() {
    titulo "Configurando repositório"

    local repo_url="https://github.com/htech19/HCTech_AI-System.git"
    local install_dir="$HOME/HCTech_AI-System"

    if [[ -d "$install_dir/.git" ]]; then
        log "Repositório já existe em $install_dir. Atualizando..."
        git -C "$install_dir" pull --ff-only 2>>"$LOG_FILE" || warn "git pull falhou, continuando..."
        PROJECT_DIR="$install_dir"
    elif [[ "$PROJECT_DIR" == "$(dirname "$SCRIPT_DIR")" ]] && [[ -f "$PROJECT_DIR/README.md" ]]; then
        ok "Executando dentro do repositório: $PROJECT_DIR"
    else
        log "Clonando repositório em $install_dir..."
        git clone "$repo_url" "$install_dir" 2>>"$LOG_FILE"
        PROJECT_DIR="$install_dir"
        ok "Repositório clonado."
    fi

    # Copiar scripts linux para o projeto
    install_linux_scripts

    ok "Repositório pronto em: $PROJECT_DIR"
}

# ─── Instalar scripts Linux no projeto ───────────────────────────────────────
install_linux_scripts() {
    log "Instalando scripts Linux no projeto..."

    local scripts_dir="$PROJECT_DIR/scripts"
    mkdir -p "$scripts_dir"

    # O próprio instalador já estará lá se foi clonado
    # Garantir que todos os .sh sejam executáveis
    find "$scripts_dir" -name "*.sh" -exec chmod +x {} \;
    chmod +x "$PROJECT_DIR/iniciar_completo.sh" 2>/dev/null || true

    ok "Scripts configurados."
}

# ─── Configurar ambiente Python (virtualenv) ──────────────────────────────────
setup_python_env() {
    titulo "Configurando ambiente Python"

    local backend_dir="$PROJECT_DIR/backend"

    if [[ ! -d "$backend_dir" ]]; then
        erro "Diretório backend/ não encontrado em $PROJECT_DIR"
        return 1
    fi

    cd "$backend_dir"

    # Criar virtualenv se não existir
    if [[ ! -d ".venv" ]]; then
        log "Criando virtualenv Python..."
        python -m venv .venv 2>>"$LOG_FILE"
        ok "virtualenv criado em backend/.venv"
    else
        ok "virtualenv já existe."
    fi

    # Ativar e instalar dependências
    log "Instalando dependências Python..."
    # shellcheck source=/dev/null
    source .venv/bin/activate

    pip install --upgrade pip 2>>"$LOG_FILE"

    if [[ -f "requirements.txt" ]]; then
        pip install -r requirements.txt 2>>"$LOG_FILE"
        ok "requirements.txt instalado."
    else
        # Instalar dependências base do projeto
        warn "requirements.txt não encontrado. Instalando dependências padrão..."
        pip install \
            "fastapi==0.115.0" \
            "uvicorn[standard]==0.30.0" \
            "sqlalchemy[asyncio]==2.0.35" \
            "aiosqlite==0.20.0" \
            "python-dotenv==1.0.1" \
            "httpx==0.27.2" \
            "anthropic==0.34.2" \
            "openai==1.45.0" \
            "apscheduler==3.10.4" \
            "loguru==0.7.2" \
            "pydantic==2.9.2" \
            "pydantic-settings==2.5.2" \
            "python-multipart==0.0.9" \
            "alembic==1.13.3" \
            "passlib[bcrypt]==1.7.4" \
            "python-jose[cryptography]==3.3.0" \
            "aiofiles==24.1.0" \
            "pillow==10.4.0" \
            2>>"$LOG_FILE"
        ok "Dependências padrão instaladas."

        # Gerar requirements.txt para referência futura
        pip freeze > requirements.txt
        log "requirements.txt gerado."
    fi

    deactivate
    cd "$PROJECT_DIR"

    ok "Ambiente Python configurado."
}

# ─── Configurar frontend Node.js ──────────────────────────────────────────────
setup_node_env() {
    titulo "Configurando frontend Next.js"

    local frontend_dir="$PROJECT_DIR/frontend"

    if [[ ! -d "$frontend_dir" ]]; then
        erro "Diretório frontend/ não encontrado em $PROJECT_DIR"
        return 1
    fi

    cd "$frontend_dir"

    # Verificar se tem package.json
    if [[ ! -f "package.json" ]]; then
        erro "package.json não encontrado em frontend/"
        return 1
    fi

    log "Instalando dependências Node.js..."

    # Usar npm ci se houver package-lock.json, senão npm install
    if [[ -f "package-lock.json" ]]; then
        npm ci 2>>"$LOG_FILE"
    else
        npm install 2>>"$LOG_FILE"
    fi

    ok "Dependências Node.js instaladas."
    cd "$PROJECT_DIR"
}

# ─── Configurar .env ──────────────────────────────────────────────────────────
setup_env() {
    titulo "Configurando variáveis de ambiente"

    local env_file="$PROJECT_DIR/backend/.env"
    local env_example="$PROJECT_DIR/backend/.env.example"

    if [[ -f "$env_file" ]]; then
        warn ".env já existe. Pulando criação (não será sobrescrito)."
        return 0
    fi

    # Gerar chave secreta aleatória
    local secret_key
    secret_key=$(python -c "import secrets; print(secrets.token_hex(32))")

    cat > "$env_file" << EOF
# ═══════════════════════════════════════════════════════════
# HC TECH AI SYSTEM — Configuração de Ambiente
# Gerado automaticamente em $(date '+%Y-%m-%d %H:%M:%S')
# ═══════════════════════════════════════════════════════════

# ─── App ────────────────────────────────────────────────
APP_NAME="HC Tech AI System"
APP_ENV=development
DEBUG=true
SECRET_KEY=${secret_key}

# ─── Servidor ───────────────────────────────────────────
HOST=0.0.0.0
PORT=8000
FRONTEND_URL=http://localhost:3000
BACKEND_URL=http://localhost:8000

# ─── Banco de dados ─────────────────────────────────────
DATABASE_URL=sqlite+aiosqlite:///./data/hctech.db

# ─── Ollama (IA Local — padrão) ──────────────────────────
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_DEFAULT_MODEL=llama3.2:3b
OLLAMA_TIMEOUT=120

# ─── OpenAI (opcional) ──────────────────────────────────
OPENAI_API_KEY=
OPENAI_DEFAULT_MODEL=gpt-4o-mini

# ─── Anthropic (opcional) ───────────────────────────────
ANTHROPIC_API_KEY=
ANTHROPIC_DEFAULT_MODEL=claude-3-haiku-20240307

# ─── Agentes ─────────────────────────────────────────────
AI_PROVIDER=ollama
AI_TEMPERATURE=0.7
AI_MAX_TOKENS=4096
AI_TIMEOUT=120

# ─── Negócio ─────────────────────────────────────────────
BUSINESS_NAME="HC Tech InfoCell"
BUSINESS_CITY="São Bernardo do Campo"
BUSINESS_STATE=SP
BUSINESS_REGION="Grande ABC"
BUSINESS_SINCE=2011
BUSINESS_WEBSITE=https://www.hctechinfocell.com.br
BUSINESS_SPECIALTIES="smartphones,notebooks,tablets"

# ─── APScheduler ─────────────────────────────────────────
SCHEDULER_ENABLED=true
SCHEDULER_TIMEZONE=America/Sao_Paulo

# ─── Logs ────────────────────────────────────────────────
LOG_LEVEL=INFO
LOG_FILE=logs/hctech.log
EOF

    # Criar .env.example sem valores sensíveis
    if [[ ! -f "$env_example" ]]; then
        sed 's/SECRET_KEY=.*/SECRET_KEY=GERE_UMA_CHAVE_ALEATORIA/' "$env_file" \
          | sed 's/OPENAI_API_KEY=.*/OPENAI_API_KEY=sua_chave_aqui/' \
          | sed 's/ANTHROPIC_API_KEY=.*/ANTHROPIC_API_KEY=sua_chave_aqui/' \
          > "$env_example"
    fi

    ok ".env criado em: $env_file"
}

# ─── Criar diretórios necessários ────────────────────────────────────────────
setup_dirs() {
    log "Criando diretórios necessários..."

    local dirs=(
        "$PROJECT_DIR/data"
        "$PROJECT_DIR/backend/logs"
        "$PROJECT_DIR/backend/data"
        "$PROJECT_DIR/backend/uploads"
        "$PROJECT_DIR/backend/backups"
    )

    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done

    ok "Diretórios criados."
}

# ─── Instalar units systemd (opcional) ───────────────────────────────────────
setup_systemd() {
    titulo "Configurando systemd (opcional)"

    echo ""
    read -rp "Instalar serviços systemd (auto-start na inicialização)? [s/N]: " install_sd
    install_sd="${install_sd:-N}"

    if [[ "${install_sd,,}" != "s" ]]; then
        log "Pulando configuração do systemd."
        return 0
    fi

    local systemd_user_dir="$HOME/.config/systemd/user"
    mkdir -p "$systemd_user_dir"

    # ── hctech-backend.service ──
    cat > "$systemd_user_dir/hctech-backend.service" << EOF
[Unit]
Description=HC Tech AI System — Backend (FastAPI)
After=network.target hctech-ollama.service
Wants=hctech-ollama.service

[Service]
Type=simple
WorkingDirectory=${PROJECT_DIR}/backend
ExecStart=${PROJECT_DIR}/backend/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
Restart=on-failure
RestartSec=5
Environment=PYTHONUNBUFFERED=1
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

    # ── hctech-frontend.service ──
    cat > "$systemd_user_dir/hctech-frontend.service" << EOF
[Unit]
Description=HC Tech AI System — Frontend (Next.js)
After=hctech-backend.service

[Service]
Type=simple
WorkingDirectory=${PROJECT_DIR}/frontend
ExecStart=/usr/bin/npm run dev
Restart=on-failure
RestartSec=5
Environment=NODE_ENV=development
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

    # Recarregar e habilitar
    systemctl --user daemon-reload
    systemctl --user enable hctech-backend.service hctech-frontend.service

    ok "Serviços systemd instalados e habilitados."
    log "Para iniciar: systemctl --user start hctech-backend hctech-frontend"
    log "Para ver logs: journalctl --user -u hctech-backend -f"
}

# ─── Inicializar banco de dados ───────────────────────────────────────────────
init_database() {
    titulo "Inicializando banco de dados"

    local backend_dir="$PROJECT_DIR/backend"

    cd "$backend_dir"
    # shellcheck source=/dev/null
    source .venv/bin/activate

    log "Rodando migrações / inicialização do DB..."

    # Tentar alembic primeiro
    if [[ -f "alembic.ini" ]]; then
        alembic upgrade head 2>>"$LOG_FILE" && ok "Migrações Alembic aplicadas." || warn "Alembic falhou, tentando init direto..."
    fi

    # Script de inicialização direto
    if python -c "from app.database import init_db; import asyncio; asyncio.run(init_db())" 2>>"$LOG_FILE"; then
        ok "Banco de dados inicializado."
    else
        warn "init_db falhou. Banco será criado na primeira execução."
    fi

    deactivate
    cd "$PROJECT_DIR"
}

# ─── Treinar agentes ──────────────────────────────────────────────────────────
train_agents() {
    titulo "Treinando agentes"

    echo ""
    read -rp "Treinar os 5 agentes agora? (requer backend rodando) [s/N]: " train
    train="${train:-N}"

    if [[ "${train,,}" != "s" ]]; then
        log "Pule por agora. Execute depois: python scripts/treinar_agentes_hctech.py"
        return 0
    fi

    local script="$PROJECT_DIR/scripts/treinar_agentes_hctech.py"

    if [[ ! -f "$script" ]]; then
        warn "Script de treinamento não encontrado: $script"
        return 0
    fi

    cd "$PROJECT_DIR/backend"
    source .venv/bin/activate
    python "$script" 2>>"$LOG_FILE" && ok "Agentes treinados!" || warn "Falha no treinamento. Execute manualmente depois."
    deactivate
    cd "$PROJECT_DIR"
}

# ─── Verificação final ────────────────────────────────────────────────────────
final_check() {
    titulo "Verificação final"

    local all_ok=true

    # Python
    if python --version &>/dev/null; then
        ok "Python: $(python --version)"
    else
        erro "Python: não encontrado"
        all_ok=false
    fi

    # Node
    if node --version &>/dev/null; then
        ok "Node.js: $(node --version)"
    else
        erro "Node.js: não encontrado"
        all_ok=false
    fi

    # Ollama
    if command -v ollama &>/dev/null; then
        ok "Ollama: $(ollama --version 2>/dev/null || echo 'instalado')"
    else
        warn "Ollama: não encontrado (opcional para IA local)"
    fi

    # Git
    if git --version &>/dev/null; then
        ok "Git: $(git --version)"
    else
        erro "Git: não encontrado"
        all_ok=false
    fi

    # virtualenv backend
    if [[ -f "$PROJECT_DIR/backend/.venv/bin/activate" ]]; then
        ok "Python venv: OK"
    else
        erro "Python venv: não criado"
        all_ok=false
    fi

    # node_modules frontend
    if [[ -d "$PROJECT_DIR/frontend/node_modules" ]]; then
        ok "Node modules: OK"
    else
        warn "Node modules: não instalados"
    fi

    # .env
    if [[ -f "$PROJECT_DIR/backend/.env" ]]; then
        ok ".env: OK"
    else
        erro ".env: não criado"
        all_ok=false
    fi

    echo ""
    if [[ "$all_ok" == "true" ]]; then
        ok "✅ Tudo instalado com sucesso!"
    else
        warn "⚠️  Instalação com avisos. Verifique os erros acima."
    fi

    echo ""
    echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║        INSTALAÇÃO CONCLUÍDA!                ║${NC}"
    echo -e "${BOLD}${GREEN}╠══════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}${GREEN}║  Para iniciar o sistema:                    ║${NC}"
    echo -e "${BOLD}${GREEN}║                                              ║${NC}"
    echo -e "${BOLD}${GREEN}║  cd ${PROJECT_DIR}${NC}"
    echo -e "${BOLD}${GREEN}║  ./iniciar_completo.sh                      ║${NC}"
    echo -e "${BOLD}${GREEN}║                                              ║${NC}"
    echo -e "${BOLD}${GREEN}║  Frontend:  http://localhost:3000            ║${NC}"
    echo -e "${BOLD}${GREEN}║  Backend:   http://localhost:8000            ║${NC}"
    echo -e "${BOLD}${GREEN}║  API Docs:  http://localhost:8000/docs       ║${NC}"
    echo -e "${BOLD}${GREEN}║  Ollama:    http://localhost:11434           ║${NC}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Log completo: ${CYAN}$LOG_FILE${NC}"
}

# ─── MAIN ─────────────────────────────────────────────────────────────────────
main() {
    banner
    echo -e "${YELLOW}Log sendo gravado em: $LOG_FILE${NC}\n"

    check_root
    check_arch
    check_internet

    install_yay
    install_system_deps
    install_ollama
    setup_repo
    setup_dirs
    setup_python_env
    setup_node_env
    setup_env
    init_database
    setup_systemd
    train_agents
    final_check
}

main "$@"
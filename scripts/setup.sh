#!/usr/bin/env bash
# =============================================================================
# HC TECH AI SYSTEM — Setup rápido (assume pré-requisitos instalados)
# Substitui: setup.ps1
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${CYAN}[setup]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC}    $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
erro() { echo -e "${RED}[ERRO]${NC}  $*"; exit 1; }

echo -e "\n${GREEN}━━━ HC Tech AI System — Setup Rápido ━━━${NC}\n"

# ── Backend ───────────────────────────────────────────────────────────────────
log "Configurando backend Python..."

BACKEND="$PROJECT_DIR/backend"
[[ -d "$BACKEND" ]] || erro "backend/ não encontrado."

cd "$BACKEND"

if [[ ! -d ".venv" ]]; then
    log "Criando virtualenv..."
    python -m venv .venv
fi

log "Ativando venv e instalando dependências..."
# shellcheck source=/dev/null
source .venv/bin/activate

pip install --upgrade pip --quiet

if [[ -f "requirements.txt" ]]; then
    pip install -r requirements.txt --quiet
    ok "requirements.txt instalado."
else
    warn "requirements.txt não encontrado."
fi

deactivate
cd "$PROJECT_DIR"

# ── Frontend ──────────────────────────────────────────────────────────────────
log "Configurando frontend Node.js..."

FRONTEND="$PROJECT_DIR/frontend"
[[ -d "$FRONTEND" ]] || erro "frontend/ não encontrado."

cd "$FRONTEND"

if [[ ! -f "package.json" ]]; then
    erro "package.json não encontrado em frontend/"
fi

log "Instalando dependências npm..."
npm install --silent
ok "node_modules instalados."
cd "$PROJECT_DIR"

# ── .env ──────────────────────────────────────────────────────────────────────
if [[ ! -f "$BACKEND/.env" ]]; then
    warn ".env não encontrado. Copiando .env.example..."
    if [[ -f "$BACKEND/.env.example" ]]; then
        cp "$BACKEND/.env.example" "$BACKEND/.env"
        warn "⚠️  Edite $BACKEND/.env com suas configurações!"
    else
        warn ".env.example também não encontrado. Crie o .env manualmente."
    fi
else
    ok ".env já existe."
fi

# ── Diretórios ────────────────────────────────────────────────────────────────
mkdir -p "$PROJECT_DIR"/{data,logs}
mkdir -p "$BACKEND"/{data,logs,uploads,backups}
ok "Diretórios criados."

echo ""
ok "✅ Setup concluído!"
echo -e "   Para iniciar: ${CYAN}./iniciar_completo.sh${NC}"
echo ""
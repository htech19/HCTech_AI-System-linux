#!/usr/bin/env bash
# =============================================================================
# HC TECH AI SYSTEM — Limpar repositório Git
# Substitui: Limpar-Repo.ps1
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC}  $*"; }
info() { echo -e "${CYAN}ℹ${NC}  $*"; }
erro() { echo -e "${RED}✗${NC} $*"; }

echo -e "\n${BOLD}${RED}━━━ Limpeza do Repositório Git ━━━${NC}\n"
echo -e "${YELLOW}⚠ ATENÇÃO: Esta operação remove arquivos do índice Git (não do disco).${NC}\n"

cd "$PROJECT_DIR"

if ! git rev-parse --git-dir &>/dev/null; then
    erro "Não é um repositório git."
    exit 1
fi

# ─── Arquivos/padrões a remover do índice ─────────────────────────────────────
REMOVE_PATTERNS=(
    "backend/.env"
    "backend/.venv/"
    "frontend/node_modules/"
    "**/__pycache__/"
    "**/*.pyc"
    "**/*.pyo"
    "backend/data/hctech.db"
    "backend/logs/"
    "backend/uploads/"
    "backend/backups/"
    ".pids/"
    "logs/"
    "**/.DS_Store"
    "**/*.log"
)

echo -e "${BOLD}Arquivos atualmente no índice que serão removidos:${NC}"
found_any=false

for pattern in "${REMOVE_PATTERNS[@]}"; do
    matches=$(git ls-files "$pattern" 2>/dev/null || true)
    if [[ -n "$matches" ]]; then
        echo "$matches" | while read -r f; do
            echo -e "  ${RED}−${NC} $f"
            found_any=true
        done
    fi
done

if [[ "$found_any" == "false" ]]; then
    ok "Nenhum arquivo problemático encontrado no índice."
    exit 0
fi

echo ""
read -rp "Confirma remoção do índice? (arquivos no disco NÃO serão deletados) [s/N]: " confirm
if [[ "${confirm,,}" != "s" ]]; then
    info "Operação cancelada."
    exit 0
fi

# ─── Remover do índice ────────────────────────────────────────────────────────
for pattern in "${REMOVE_PATTERNS[@]}"; do
    git rm -r --cached "$pattern" 2>/dev/null || true
done

# ─── Verificar/criar .gitignore ───────────────────────────────────────────────
gitignore="$PROJECT_DIR/.gitignore"

if [[ ! -f "$gitignore" ]]; then
    info "Criando .gitignore..."
    cat > "$gitignore" << 'GITIGNORE'
# ── Python ──────────────────────────────────
__pycache__/
*.py[cod]
*.egg-info/
dist/
build/
.eggs/
.venv/
venv/
env/

# ── Node.js ──────────────────────────────────
node_modules/
.next/
out/
.nuxt/
dist/

# ── Ambiente ─────────────────────────────────
.env
.env.local
.env.*.local
*.env

# ── Banco de dados ───────────────────────────
*.db
*.sqlite
*.sqlite3

# ── Logs ─────────────────────────────────────
*.log
logs/
backend/logs/

# ── Uploads/backups ───────────────────────────
backend/uploads/
backend/backups/
uploads/
backups/

# ── PIDs ─────────────────────────────────────
.pids/
*.pid

# ── Editores ─────────────────────────────────
.vscode/settings.json
.idea/
*.swp
*.swo
*~
.DS_Store
Thumbs.db

# ── Segurança ────────────────────────────────
*.pem
*.key
*.crt
secrets/
GITIGNORE
    ok ".gitignore criado."
fi

# ─── Commit das limpezas ──────────────────────────────────────────────────────
echo ""
read -rp "Criar commit com as limpezas? [s/N]: " do_commit
if [[ "${do_commit,,}" == "s" ]]; then
    git add .gitignore 2>/dev/null || true
    git commit -m "chore: remover arquivos sensíveis/desnecessários do índice

- Remove .env, .venv, node_modules, __pycache__ do tracking
- Atualiza/cria .gitignore completo
- Gerado por scripts/limpar-repo.sh" 2>/dev/null || warn "Nada novo para commitar."
    ok "Commit criado."
fi

echo ""
ok "Limpeza concluída!"
info "Dica: Depois execute 'git push' para aplicar no GitHub."
echo ""
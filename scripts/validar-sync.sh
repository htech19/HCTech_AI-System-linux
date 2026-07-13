#!/usr/bin/env bash
# =============================================================================
# HC TECH AI SYSTEM — Validar sincronização com GitHub
# Substitui: Validar-Sync.ps1
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

echo -e "\n${BOLD}${CYAN}━━━ Validação de Sincronização — HC Tech AI ━━━${NC}\n"

cd "$PROJECT_DIR"

# Verificar se é um repositório git
if ! git rev-parse --git-dir &>/dev/null; then
    erro "Não é um repositório git: $PROJECT_DIR"
    exit 1
fi

# ── Branch atual ──────────────────────────────────────────────────────────────
current_branch=$(git branch --show-current)
info "Branch atual: ${BOLD}$current_branch${NC}"

# ── Fetch para atualizar referências remotas ──────────────────────────────────
info "Buscando informações do repositório remoto..."
git fetch origin 2>/dev/null || warn "Fetch falhou (sem internet?)"

# ── Comparar commits ──────────────────────────────────────────────────────────
local_commit=$(git rev-parse HEAD)
remote_commit=$(git rev-parse "origin/$current_branch" 2>/dev/null || echo "DESCONHECIDO")

echo ""
info "Commit local:  ${local_commit:0:12}"
info "Commit remoto: ${remote_commit:0:12}"

if [[ "$local_commit" == "$remote_commit" ]]; then
    ok "Local sincronizado com o remoto!"
else
    # Verificar se está atrás, adiantado ou divergido
    ahead=$(git rev-list --count "origin/$current_branch..HEAD" 2>/dev/null || echo 0)
    behind=$(git rev-list --count "HEAD..origin/$current_branch" 2>/dev/null || echo 0)

    [[ "$ahead" -gt 0 ]]  && warn "$ahead commit(s) locais NÃO enviados ao GitHub."
    [[ "$behind" -gt 0 ]] && warn "$behind commit(s) no GitHub NÃO baixados localmente."
fi

# ── Arquivos modificados ──────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Arquivos modificados (não comitados):${NC}"
modified=$(git status --porcelain)

if [[ -z "$modified" ]]; then
    ok "Nenhum arquivo modificado."
else
    echo "$modified" | while read -r line; do
        status="${line:0:2}"
        file="${line:3}"
        case "${status// /}" in
            M)  echo -e "  ${YELLOW}M${NC}  $file (modificado)" ;;
            A)  echo -e "  ${GREEN}A${NC}  $file (adicionado)" ;;
            D)  echo -e "  ${RED}D${NC}  $file (deletado)" ;;
            ??) echo -e "  ${CYAN}?${NC}  $file (não rastreado)" ;;
            *)  echo -e "  ${NC}$status${NC}  $file" ;;
        esac
    done
fi

# ── Arquivos nunca versionados ────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Arquivos não rastreados:${NC}"
untracked=$(git ls-files --others --exclude-standard)

if [[ -z "$untracked" ]]; then
    ok "Nenhum arquivo não rastreado."
else
    echo "$untracked" | while read -r f; do
        echo -e "  ${CYAN}?${NC}  $f"
    done
fi

# ── .gitignore check ──────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Verificando arquivos sensíveis no índice:${NC}"

sensitive_patterns=(".env" "*.key" "*.pem" "secrets" "__pycache__" ".venv" "node_modules")
found_sensitive=false

for pattern in "${sensitive_patterns[@]}"; do
    matches=$(git ls-files "$pattern" 2>/dev/null || true)
    if [[ -n "$matches" ]]; then
        erro "Arquivo sensível no Git: $matches"
        found_sensitive=true
    fi
done

[[ "$found_sensitive" == "false" ]] && ok "Nenhum arquivo sensível encontrado no índice."

# ── Resumo ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}━━━ Resumo ━━━${NC}"
echo -e "  Branch:  $current_branch"
echo -e "  Commit:  ${local_commit:0:12}"
echo -e "  Remote:  $(git remote get-url origin 2>/dev/null || echo 'sem remote')"
echo ""

# Sugerir ações
if [[ "$ahead" -gt 0 ]] 2>/dev/null; then
    echo -e "${YELLOW}➜ Para enviar commits: ${BOLD}git push origin $current_branch${NC}"
fi
if [[ "$behind" -gt 0 ]] 2>/dev/null; then
    echo -e "${YELLOW}➜ Para baixar commits: ${BOLD}git pull origin $current_branch${NC}"
fi
if [[ -n "$modified" ]]; then
    echo -e "${YELLOW}➜ Para commitar: ${BOLD}git add -A && git commit -m 'sua mensagem'${NC}"
fi
echo ""
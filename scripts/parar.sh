#!usrbinenv bash
# =============================================================================
# HC TECH AI SYSTEM — Parar todos os serviços
# =============================================================================

set -uo pipefail

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
PROJECT_DIR=$(dirname $SCRIPT_DIR)
PID_DIR=$PROJECT_DIR.pids

RED='033[0;31m'
GREEN='033[0;32m'
YELLOW='033[1;33m'
CYAN='033[0;36m'
NC='033[0m'

log()  { echo -e ${CYAN}[$(date '+%H%M%S')]${NC} $; }
ok()   { echo -e ${GREEN}✓${NC} $; }
warn() { echo -e ${YELLOW}⚠${NC}  $; }

echo -e n${RED}━━━ Parando HC Tech AI System ━━━${NC}n

# Matar via PIDs salvos
if [[ -d $PID_DIR ]]; then
    for pid_file in $PID_DIR.pid; do
        if [[ -f $pid_file ]]; then
            local_pid=$(cat $pid_file)
            local_name=$(basename $pid_file .pid)

            if kill -0 $local_pid 2devnull; then
                kill -TERM $local_pid 2devnull
                log Encerrado $local_name (PID $local_pid)
            else
                warn $local_name (PID $local_pid) já não estava rodando.
            fi
            rm -f $pid_file
        fi
    done
fi

# Por garantia, matar pelas portas
for port in 8000 3000; do
    pids=$(lsof -ti $port 2devnull  true)
    if [[ -n $pids ]]; then
        kill -TERM $pids 2devnull  true
        ok Porta $port liberada.
    fi
done

# Não matar Ollama por padrão (pode estar sendo usado por outros)
echo 
read -rp Parar Ollama também [sN]  stop_ollama
if [[ ${stop_ollama,,} == s ]]; then
    if systemctl is-active --quiet ollama.service 2devnull; then
        sudo systemctl stop ollama.service
        ok Serviço Ollama parado.
    else
        pkill -x ollama 2devnull && ok Processo ollama encerrado.  warn Ollama não estava rodando.
    fi
fi

echo 
ok Sistema encerrado com sucesso.
echo 
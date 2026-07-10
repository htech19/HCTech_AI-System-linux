# ═══ INSTALAÇÃO (máquina zerada) ═══════════════════════════════════

# 1. Clonar o repositório
git clone https://github.com/htech19/HCTech_AI-System.git
cd HCTech_AI-System

# 2. Tornar scripts executáveis
chmod +x scripts/*.sh iniciar_completo.sh

# 3. Instalar tudo
./scripts/instalar-hctech.sh


# ═══ USO DIÁRIO ════════════════════════════════════════════════════

# Iniciar sistema completo
./iniciar_completo.sh

# Parar sistema
./scripts/parar.sh

# ═══ MANUTENÇÃO ════════════════════════════════════════════════════

# Verificar sync com GitHub
./scripts/validar-sync.sh

# Limpar repositório
./scripts/limpar-repo.sh

# Treinar agentes (backend rodando)
cd backend && source .venv/bin/activate
python ../scripts/treinar_agentes_hctech.py

# ═══ SYSTEMD (auto-start) ═════════════════════════════════════════

cp systemd/hctech-*.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now hctech-backend hctech-frontend

# Ver logs em tempo real
journalctl --user -u hctech-backend -f
journalctl --user -u hctech-frontend -f

# ═══ OLLAMA ════════════════════════════════════════════════════════

# Baixar modelo
ollama pull llama3.2:3b

# Listar modelos disponíveis
ollama list

# Testar modelo
ollama run llama3.2:3b "Olá, você é o assistente HC Tech!"
<div align="center">

# 🤖 HC TECH AI SYSTEM
### `v2.1-linux` — Plataforma Híbrida de IA para Assistência Técnica
### Edição CachyOS / Arch Linux

[![Python](https://img.shields.io/badge/Python-3.12-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Next.js](https://img.shields.io/badge/Next.js-14.2-000000?style=for-the-badge&logo=next.js&logoColor=white)](https://nextjs.org)
[![Ollama](https://img.shields.io/badge/Ollama-IA_Local-FF6B00?style=for-the-badge&logo=ollama&logoColor=white)](https://ollama.ai)
[![Arch Linux](https://img.shields.io/badge/Arch_Linux-CachyOS-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://cachyos.org)
[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://gnu.org/software/bash)
[![License](https://img.shields.io/badge/Licença-Proprietária-red?style=for-the-badge)](LICENSE)

**5 agentes de IA autônomos · IA local ou em nuvem · 100% Linux · Zero dependência de API paga**

[🚀 Instalação](#-instalação-rápida) · [🧠 Agentes](#-os-5-agentes) · [🏗️ Arquitetura](#️-arquitetura) · [🔧 Scripts](#-scripts-do-projeto) · [🐧 Linux Guide](#-guia-linux--cachyos) · [❓ FAQ](#-faq)

</div>

---

## 📌 Sobre este repositório

Este é o **port oficial para Linux** do [HC TECH AI SYSTEM](https://github.com/htech19/HCTech_AI-System) — originalmente desenvolvido para Windows 10/11.

Todos os scripts PowerShell foram reescritos em **Bash puro**, com suporte a **systemd**, **pacman** e **yay (AUR)**.
O backend (Python/FastAPI) e o frontend (Next.js) são **idênticos** ao projeto original.

| | Projeto Original | Este Repositório |
|---|---|---|
| 🖥️ Sistema | Windows 10/11 | CachyOS / Arch Linux |
| 📦 Gerenciador | winget | pacman + yay |
| 📜 Scripts | PowerShell .ps1 / .bat | Bash .sh |
| ⚙️ Serviços | Task Scheduler | systemd --user |
| 🤖 IA local | Ollama (Windows) | Ollama (Linux) |
| 🐍 Backend | FastAPI idêntico | FastAPI idêntico |
| ⚛️ Frontend | Next.js idêntico | Next.js idêntico |

---

## ⚡ O que é isso

Sistema de gestão com **inteligência artificial embarcada** para a **HC Tech InfoCell** — assistência técnica de smartphones e notebooks no Grande ABC, São Bernardo do Campo/SP, desde 2011.

> 🔗 Site: [www.hctechinfocell.com.br](https://www.hctechinfocell.com.br)
> 📦 Repo Windows: [github.com/htech19/HCTech_AI-System](https://github.com/htech19/HCTech_AI-System)

---

## 🧠 Os 5 Agentes

| | Agente | Missão |
|---|---|---|
| 🧭 | **HC-CEO** | Coordenador estratégico |
| 🔍 | **HC-SEO** | SEO local, Google Maps, Schema.org |
| 📱 | **HC-SOCIAL** | Facebook e Instagram |
| ✍️ | **HC-CONTENT** | Copywriting e blog |
| 💻 | **HC-CODE** | Desenvolvimento e automação |

---

## 🏗️ Arquitetura

\\\
┌─────────────────────┐        ┌──────────────────────┐
│   Next.js 14         │◄──────►│   FastAPI (Python)   │
│   Frontend (:3000)   │        │   Backend (:8000)    │
└─────────────────────┘        └──────────┬───────────┘
                                           │
                     ┌─────────────────────┼──────────────────┐
                     ▼                     ▼                  ▼
               ┌──────────┐         ┌──────────┐      ┌─────────────┐
               │  Ollama   │         │  OpenAI  │      │  Anthropic  │
               │  (local)  │         │  (nuvem) │      │   (nuvem)   │
               └──────────┘         └──────────┘      └─────────────┘
                     │
                     ▼
            ┌──────────────────┐
            │  SQLite          │
            │  (agentes,       │
            │   conversas,     │
            │   dados)         │
            └──────────────────┘
\\\

---

## 📁 Estrutura do Repositório

\\\
HCTech_AI-System-linux/
│
├── 📜 README.md
├── 📜 iniciar_completo.sh       ← Entry point: sobe tudo
├── 📜 .env.example              ← Template de configuração
├── 📜 Guia de Uso Rápido.md
│
├── scripts/
│   ├── instalar-hctech.sh       ← Instalador completo
│   ├── setup.sh                 ← Só dependências
│   ├── parar.sh                 ← Para todos os serviços
│   ├── validar-sync.sh          ← Compara local × GitHub
│   └── limpar-repo.sh           ← Limpa Git
│
└── systemd/
    ├── hctech-backend.service   ← Auto-start backend
    ├── hctech-frontend.service  ← Auto-start frontend
    └── hctech-ollama.service    ← Auto-start ollama
\\\

> O backend/ e frontend/ são clonados do repositório Windows durante a instalação.

---

## 🚀 Instalação Rápida

### Pré-requisitos

| Requisito | Mínimo | Recomendado |
|---|---|---|
| OS | Arch Linux | CachyOS (último ISO) |
| RAM | 8 GB | 16 GB |
| Armazenamento | 20 GB | 50 GB |
| CPU | x86_64 | x86_64 com AVX2 |

### Instalar

\\\ash
# 1. Clonar
git clone https://github.com/htech19/HCTech_AI-System-linux.git
cd HCTech_AI-System-linux

# 2. Permissão
chmod +x scripts/*.sh iniciar_completo.sh

# 3. Instalar tudo
./scripts/instalar-hctech.sh

# 4. Iniciar
./iniciar_completo.sh
\\\

| 🌐 Serviço | URL |
|---|---|
| Interface Web | http://localhost:3000 |
| API REST | http://localhost:8000 |
| Docs interativos | http://localhost:8000/docs |
| IA Local | http://localhost:11434 |

---

## 🔧 Scripts do Projeto

| Script | Equivalente Windows | O que faz |
|---|---|---|
| instalar-hctech.sh | Instalar-HCTechAI.ps1 | Instalação completa |
| setup.sh | setup.ps1 | Só dependências |
| parar.sh | (não existia) | Para todos os serviços |
| validar-sync.sh | Validar-Sync.ps1 | Compara local × GitHub |
| limpar-repo.sh | Limpar-Repo.ps1 | Limpa Git |
| iniciar_completo.sh | iniciar_completo.bat | Sobe o sistema |

\\\ash
./scripts/parar.sh
./scripts/validar-sync.sh
./scripts/limpar-repo.sh
\\\

---

## 🐧 Guia Linux / CachyOS

### systemd — Auto-start no login

\\\ash
cp systemd/hctech-*.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now hctech-backend hctech-frontend

# Logs
journalctl --user -u hctech-backend -f
journalctl --user -u hctech-frontend -f
\\\

### Ollama

\\\ash
ollama pull llama3.2:3b     # ~2GB leve e rápido
ollama pull llama3.1:8b     # ~5GB mais capaz
ollama list
ollama run llama3.2:3b "Olá, HC Tech!"
\\\

### Logs

\\\ash
tail -f logs/backend.log
tail -f logs/frontend.log
tail -f logs/*.log
\\\

### Atualizar

\\\ash
git pull origin main
cd backend && source .venv/bin/activate
pip install -r requirements.txt --upgrade && deactivate
cd frontend && npm install
./scripts/parar.sh && ./iniciar_completo.sh
\\\

---

## 🔐 Configuração .env

\\\ash
cp .env.example backend/.env
nano backend/.env

# Gerar SECRET_KEY
python -c "import secrets; print(secrets.token_hex(32))"
\\\

---

## 🔄 Diferenças Windows → Linux

| Aspecto | Windows | CachyOS/Linux |
|---|---|---|
| Gerenciador | winget | pacman + yay |
| Scripts | .ps1 / .bat | .sh (Bash) |
| Processos bg | Janelas separadas | nohup + PIDs |
| Auto-start | Task Scheduler | systemd --user |
| Abrir browser | Start-Process | xdg-open |
| Venv ativar | .venv\Scripts\activate | source .venv/bin/activate |
| Matar porta | taskkill | kill \ |
| Logs | Event Viewer | journalctl |

---

## ❓ FAQ

**Ollama não responde na porta 11434**
\\\ash
systemctl status ollama
ollama serve &
curl http://localhost:11434/api/tags
\\\

**Erro Module not found no backend**
\\\ash
cd backend && source .venv/bin/activate
pip install -r requirements.txt
\\\

**Frontend não conecta no backend**
\\\ash
curl http://localhost:8000/health
grep FRONTEND_URL backend/.env
\\\

**Resetar banco de dados**
\\\ash
cp backend/data/hctech.db backend/backups/hctech-backup-\.db
rm backend/data/hctech.db
cd backend && source .venv/bin/activate
python -c "from app.database import init_db; import asyncio; asyncio.run(init_db())"
\\\

---

## 📄 Licença

**Proprietária** — © 2024 HC Tech InfoCell. Todos os direitos reservados.

---

<div align="center">

**HC Tech InfoCell** · São Bernardo do Campo/SP · Grande ABC · desde 2011

🐧 Feito para rodar 100% local no Linux — sem depender de ninguém.

*Repo Windows:* [htech19/HCTech_AI-System](https://github.com/htech19/HCTech_AI-System) |
*Este repo:* [htech19/HCTech_AI-System-linux](https://github.com/htech19/HCTech_AI-System-linux)

</div>

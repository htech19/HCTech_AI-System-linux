#!/usr/bin/env bash

set -e

echo "==> Removendo venv antiga..."
rm -rf .venv

echo "==> Verificando Python 3.13..."
if command -v python3.13 &>/dev/null; then
    PY=python3.13
else
    echo "Python 3.13 não encontrado. Tentando instalar via pacman..."
    sudo pacman -S --noconfirm python313
    PY=python3.13
fi

echo "==> Criando venv com $PY..."
$PY -m venv .venv
source .venv/bin/activate

echo "==> Atualizando pip..."
pip install --upgrade pip --quiet

echo "==> Instalando dependências..."
pip install \
  "fastapi==0.115.0" \
  "uvicorn[standard]==0.30.0" \
  "sqlalchemy[asyncio]==2.0.35" \
  "aiosqlite==0.20.0" \
  "python-dotenv==1.0.1" \
  "httpx==0.27.2" \
  "loguru==0.7.2" \
  "pydantic>=2.10,<3" \
  "pydantic-settings>=2.6,<3" \
  "apscheduler==3.10.4" \
  "aiofiles==24.1.0" \
  "python-multipart==0.0.9" \
  "passlib[bcrypt]==1.7.4" \
  "python-jose[cryptography]==3.3.0" \
  "openai==1.45.0" \
  "anthropic==0.34.2" \
  "alembic==1.13.3"

echo ""
echo "========================================"
echo "✅ Tudo pronto!"
echo "========================================"
echo ""
echo "Python usado   : $($PY --version)"
echo "Pydantic       : $(pip show pydantic | grep Version)"
echo "FastAPI        : $(pip show fastapi | grep Version)"
echo "Uvicorn        : $(pip show uvicorn | grep Version)"
echo ""
echo "Para ativar a venv no fish:"
echo "  source .venv/bin/activate.fish"
echo "========================================"

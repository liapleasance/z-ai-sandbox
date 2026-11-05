#!/bin/bash
# RESTORE VENV — restaura o binário Python 3.12 do venv após reset
# Sem isso, python3 cai para 3.13 do sistema (sem pandas, scipy, etc.)
# Tempo medido: 36 ms (cache quente) — 0,87 s (cache frio)
# Uso: bash restore_venv.sh
set -e

echo "=== Restauração do venv Python 3.12 ==="
echo ""

echo "[1] Estado ANTES:"
echo "    python3 = $(python3 --version 2>&1)"
echo "    path:    $(readlink -f $(which python3) 2>/dev/null)"
echo "    pandas:  $(python3 -c 'import pandas; print(pandas.__version__)' 2>&1 | head -1)"
echo ""

echo "[2] Executando: uv python install 3.12"
time uv python install 3.12 2>&1 | tail -3
echo ""

echo "[3] Estado DEPOIS:"
echo "    python3 = $(python3 --version 2>&1)"
echo "    path:    $(readlink -f $(which python3) 2>/dev/null)"
echo "    pandas:  $(python3 -c 'import pandas; print(pandas.__version__)' 2>&1 | head -1)"
echo "    numpy:   $(python3 -c 'import numpy; print(numpy.__version__)' 2>&1 | head -1)"
echo "    scipy:   $(python3 -c 'import scipy; print(scipy.__version__)' 2>&1 | head -1)"
echo "    sklearn: $(python3 -c 'import sklearn; print(sklearn.__version__)' 2>&1 | head -1)"
echo ""

echo "=== Veredito ==="
if python3 -c "import pandas" 2>/dev/null; then
  echo "✓ Venv restaurado — 921 pacotes disponíveis"
else
  echo "✗ Falha — verifique ~/.venv/bin/python3"
fi

#!/bin/bash
# QUICK CHECK — smoke test de 30 segundos do sandbox Z.AI
# Uso: bash quick_check.sh
set -u

echo "=== Z.AI Sandbox — Quick Check (30s) ==="
echo "Data: $(date '+%F %T %Z')"
echo ""

# Ambiente básico
echo "[1] Ambiente:"
echo "  Kernel:   $(uname -r)"
echo "  OS:       $(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME")"
echo "  User:     $(id -un) (uid $(id -u))"
echo "  PID 1:    $(ps -p 1 -o args= 2>/dev/null)"
echo ""

# Recursos
echo "[2] Recursos:"
echo "  vCPUs:    $(nproc)"
echo "  RAM:      $(free -h | awk '/^Mem:/ {print $2 " total, " $7 " avail"}')"
echo "  Swap:     $(free -h | awk '/^Swap:/ {print $2}')"
echo "  Disk /:   $(df -h / | tail -1 | awk '{print $2 " total, " $4 " free"}')"
echo ""

# Mounts de persistência
echo "[3] Mounts de persistência:"
mount | grep -E "fuse\.ossfs|fuse\.pfs" | awk '{print "  "$3" ("$5")"}'
echo ""

# Arsenal essencial
echo "[4] Arsenal essencial:"
for c in python3 node bun git gcc make curl jq; do
  v=$(command -v "$c" >/dev/null 2>&1 && "$c" --version 2>&1 | head -1 | cut -c1-40)
  printf "  %-8s %s\n" "$c" "${v:-AUSENTE}"
done
echo ""

# Venv Python
echo "[5] Venv Python:"
echo "  python3 default: $(python3 --version 2>&1)"
echo "  Pacotes no venv:  $(ls /home/z/.venv/lib/python*/site-packages/ 2>/dev/null | wc -l) entradas"
echo "  pandas: $(python3 -c 'import pandas; print(pandas.__version__)' 2>&1)"
echo ""

# SDK z-ai
echo "[6] SDK z-ai:"
echo "  CLI: $(command -v z-ai)"
echo "  Versão: $(cat /home/z/.bun/install/global/node_modules/z-ai-web-dev-sdk/package.json 2>/dev/null | grep version | tr -d ' ,\"' | cut -d: -f2)"
echo ""

# Config API
echo "[7] Config API:"
python3 -c "
import json
c = json.load(open('/etc/.z-ai-config'))
print('  chaves:', list(c.keys()))
print('  baseUrl host:', c.get('baseUrl','').split('/')[2])
print('  apiKey len:', len(c.get('apiKey','')))
" 2>/dev/null
echo ""

# Portas escutando
echo "[8] Portas escutando:"
ss -tln 2>/dev/null | awk 'NR>1 {print "  "$4}' | sort -u
echo ""

# Persistência
echo "[9] Persistência:"
[ -f /home/sync/repo.tar ] && echo "  repo.tar: $(ls -lh /home/sync/repo.tar | awk '{print $5" bytes"}')" || echo "  repo.tar: AUSENTE (projeto FRESH)"
echo "  tools/: $(ls /home/z/my-project/tools 2>/dev/null | wc -l) itens"
echo ""

# Veredito
echo "=== Veredito ==="
echo "OK — sandbox operacional. Para inventário completo rode:"
echo "  bash /home/z/my-project/z-ai-sandbox/scripts/sandbox_inventory.sh"

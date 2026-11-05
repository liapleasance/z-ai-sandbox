#!/bin/bash
# SANDBOX INVENTORY — verificação completa do Z.AI Sandbox (sem segredos na saída)
# Uso: bash sandbox_inventory.sh
#      bash sandbox_inventory.sh > inventory.txt
set -u
SEP() { printf '\n============================================================\n'; }
hdr() { SEP; printf '%s\n' "$1"; SEP; }

hdr "[1] IDENTIDADE DO AMBIENTE"
echo "Kernel:     $(uname -r)"
echo "OS:         $(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME")"
echo "Usuário:    $(id) | home: $HOME"
echo "Uptime:     $(uptime -p 2>/dev/null || uptime)"
echo "Kata/FC:    KATA_CONTAINER=${KATA_CONTAINER:-?} FC_REGION=${FC_REGION:-?} FC_FUNCTION_MEMORY_SIZE=${FC_FUNCTION_MEMORY_SIZE:-?}"
echo "PID 1:      $(ps -p 1 -o args= 2>/dev/null)"
echo "Container:  ${FC_CONTAINER_ID:-$(basename "$(cat /proc/self/cgroup 2>/dev/null | head -1 | cut -d/ -f3)" 2>/dev/null)}"

hdr "[2] CPU"
nproc | xargs echo "vCPUs:"
lscpu 2>/dev/null | grep -E "Model name|CPU\(s\):|Thread|Core|Socket|BogoMIPS|NUMA|L3" | head -10
echo -n "Total de flags: " && grep -m1 flags /proc/cpuinfo | tr ' ' '\n' | grep -cE "."
echo -n "Notáveis: " && grep -m1 flags /proc/cpuinfo | tr ' ' '\n' | grep -E "^(avx512f|amx_tile|amx_bf16|amx_int8|avx_vnni|sha_ni|aes|hypervisor)$" | tr '\n' ' ' && echo ""
echo "cgroup CPU: quota=$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us 2>/dev/null || echo N/D) period=$(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us 2>/dev/null || echo N/D) cpuset=$(cat /sys/fs/cgroup/cpuset/cpuset.cpus 2>/dev/null || echo N/D)"

hdr "[3] MEMÓRIA RAM"
grep -E "^(MemTotal|MemFree|MemAvailable|SwapTotal|Slab|Cached):" /proc/meminfo
free -h | sed -n '1,2p'
echo -n "cgroup memory.limit_in_bytes: "
cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null || echo "N/D"
echo "AVISO Sem swap = OOM Killer: processos acima de ~4 GB morrem com SIGKILL (exit 137)"

hdr "[4] DISCO E MOUNTS"
df -h 2>/dev/null | grep -vE "tmpfs|/dev/loop|proc|sysfs|cgroup|mqueue|devpts|shm"
echo "--- Mounts de persistência ---"
mount | grep -E "fuse\.ossfs|fuse\.pfs" | awk '{print $1, "->", $3, "("$5")"}'

hdr "[5] DIRETÓRIOS PRINCIPAIS"
echo "/ (raiz):          $(ls / | tr '\n' ' ')"
echo "/home/z:           $(ls -A /home/z/ 2>/dev/null | tr '\n' ' ')"
echo "/home/z/my-project: $(ls -A /home/z/my-project/ 2>/dev/null | tr '\n' ' ')"
echo "/usr/local/bin:    $(ls /usr/local/bin 2>/dev/null | tr '\n' ' ')"
echo "/app:              $(ls /app 2>&1 | head -1)  (esperado: Permission denied — plataforma)"
echo "Uso my-project:    $(du -sh /home/z/my-project 2>/dev/null | cut -f1)"
echo "Uso skills/:        $(du -sh /home/z/my-project/skills 2>/dev/null | cut -f1 || echo 'n/a')"

hdr "[6] REDE E PORTAS"
ip -brief addr 2>/dev/null | grep -v DOWN
ip route 2>/dev/null | head -1
echo "--- Portas escutando ---"
ss -tln 2>/dev/null | awk 'NR>1 {print $4}' | sort -u
echo "Bind <1024 como user: FALHA (EACCES) — use portas 3000+"

hdr "[7] LIMITES (ulimit)"
echo "open files (-n):    $(ulimit -n)"
echo "user processes (-u): $(ulimit -u)"
echo "stack size KB (-s): $(ulimit -s)"
echo "Capabilities:       CapEff=$(grep CapEff /proc/self/status | awk '{print $2}') (0 = sem caps)"

hdr "[8] ARSENAL — runtimes e build tools"
for c in python3 pip3 uv node npm bun git gcc g++ make autoconf cmake curl wget unzip zip rsync jq caddy tectonic tini soffice ffmpeg gs tesseract pandoc dot java sqlite3 convert magick; do
  p=$(command -v "$c" 2>/dev/null) && {
    v=$("$c" --version 2>&1 | head -1 | cut -c1-50)
    printf "  %-12s OK    %s\n" "$c" "${v:-$p}"
  } || printf "  %-12s AUSENTE\n" "$c"
done

hdr "[9] PYTHON — venv vs sistema"
echo "python3 (default): $(python3 --version 2>&1)"
echo "  path: $(readlink -f $(which python3))"
echo "/usr/bin/python3:  $(/usr/bin/python3 --version 2>&1)"
echo "Pacotes no venv:   $(ls /home/z/.venv/lib/python*/site-packages/ 2>/dev/null | wc -l) entradas"
echo "MCP no venv:      $(python3 -c 'import importlib.metadata as m; print(m.version("mcp"))' 2>/dev/null || echo 'n/a')"
echo "FastMCP no venv:  $(python3 -c 'import importlib.metadata as m; print(m.version("fastmcp"))' 2>/dev/null || echo 'n/a')"

hdr "[10] NODE GLOBALS"
ls /home/z/.npm-global/lib/node_modules/ 2>/dev/null || echo "  ~/.npm-global/lib/node_modules/ não encontrado"

hdr "[11] PERSISTÊNCIA — probes e snapshot"
echo "repo.tar: $(ls -la /home/sync/repo.tar 2>/dev/null | awk '{print $5" bytes", $6, $7, $8}' || echo 'AUSENTE (projeto FRESH)')"
for p in /home/z/.bun/Z-AI-PERSISTENCE-PROBE.txt /home/z/.npm/Z-AI-PERSISTENCE-PROBE.txt /home/z/my-project/PERSISTENCE_MARKER.txt; do
  [ -f "$p" ] && echo "  probe PRESENTE: $p = $(cat "$p" 2>/dev/null | head -c 40)" || echo "  probe ausente:  $p"
done
echo "tools/: $(ls /home/z/my-project/tools 2>/dev/null | tr '\n' ' ' || echo '(vazio)')"

hdr "[12] Z-AI SDK"
echo "CLI: $(command -v z-ai) ($(command -v z-ai-generate 2>/dev/null))"
echo "Pacote: $(cat /home/z/.bun/install/global/node_modules/z-ai-web-dev-sdk/package.json 2>/dev/null | grep -E '"version"' | tr -d ' ,')"
echo "Subcomandos (10):"
z-ai --help 2>&1 | grep -E "^  [a-z]" | head -10

hdr "[13] CONFIG API"
echo "Arquivo: $(ls -la /etc/.z-ai-config 2>/dev/null | awk '{print $1, $3":"$4, $5" bytes"}')"
python3 -c "
import json
c = json.load(open('/etc/.z-ai-config'))
print('Chaves:', list(c.keys()))
print('baseUrl host:', c.get('baseUrl','').split('/')[2] if 'baseUrl' in c else '?')
print('apiKey len:', len(c.get('apiKey','')))
print('token len:', len(c.get('token','')) if 'token' in c else 0)
" 2>/dev/null

hdr "[14] SERVIÇOS DA PLATAFORMA"
ps aux 2>/dev/null | grep -E "caddy|main.py|uv run|uvicorn" | grep -v grep | awk '{printf "  %-8s pid=%-6s %s\n", $1, $2, substr($0, index($0,$11), 60)}'
echo "Boot log (últimas 3 linhas):"
tail -3 /tmp/boot-timeline.log 2>/dev/null || echo "  /tmp/boot-timeline.log ausente"

SEP
echo "FIM DO INVENTÁRIO — $(date '+%F %T %Z')"
echo "Para revalidar: bash /home/z/my-project/z-ai-sandbox/scripts/sandbox_inventory.sh"

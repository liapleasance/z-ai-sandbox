#!/bin/bash
# LIST SKILLS — inventário das skills e plugins do sandbox Z.AI
# Uso: bash list_skills.sh
#      bash list_skills.sh > skills-inventory.txt

set -u

SEP() { printf '\n============================================================\n'; }
hdr() { SEP; printf '%s\n' "$1"; SEP; }

hdr "[1] SKILLS INSTALADAS (/home/z/my-project/skills/)"
installed_count=0
for d in /home/z/my-project/skills/*/; do
  [ -d "$d" ] || continue
  installed_count=$((installed_count + 1))
  name=$(basename "$d")
  skill_file=""
  for c in "SKILL.md" "skill.md" "Skill.md" "README.md"; do
    [ -f "$d$c" ] && skill_file="$d$c" && break
  done
  if [ -n "$skill_file" ]; then
    desc=$(head -20 "$skill_file" | grep -E "^description:" | head -1 | cut -d: -f2- | tr -d '"' | cut -c1-80)
    [ -z "$desc" ] && desc=$(head -10 "$skill_file" | grep -v "^#\|^---\|^$" | head -1 | cut -c1-80)
    size=$(du -sh "$d" 2>/dev/null | cut -f1)
    files=$(find "$d" -type f | wc -l)
    printf "  %-25s %5s %3d files  %s\n" "$name" "$size" "$files" "$desc"
  else
    printf "  %-25s (sem SKILL.md)\n" "$name"
  fi
done
echo ""
echo "Total instalado: $installed_count skills"

hdr "[2] SKILLS OFICIAIS DISPONÍVEIS (/home/official_skills/*.zip)"
total_zip=0
# Coleta lista de skills em array para contagem correta antes do sort
skills_list=()
for zip in /home/official_skills/*.zip; do
  [ -f "$zip" ] || continue
  total_zip=$((total_zip + 1))
  name=$(basename "$zip" .zip)
  installed=""
  [ -d "/home/z/my-project/skills/$name" ] && installed="  ✓ INSTALADA"
  skills_list+=("  $name$installed")
done
# Printa em ordem alfabética
printf '%s\n' "${skills_list[@]}" | sort
echo ""
echo "Total oficiais: $total_zip zips"

hdr "[3] STAGES (presets de skills) — /home/official_skills/stages.yaml"
if [ -f /home/official_skills/stages.yaml ]; then
  current_stage="${SANDBOX_STAGE:-unknown}"
  echo "Stage atual (env SANDBOX_STAGE): $current_stage"
  echo ""
  echo "Stages definidos:"
  grep -E "^[a-z_]+:" /home/official_skills/stages.yaml | tr -d ':' | sed 's/^/  /'
else
  echo "  stages.yaml não encontrado"
fi

hdr "[4] SKILLS DO USUÁRIO (/home/user_skills/)"
if [ -d /home/user_skills ]; then
  found_user=0
  for f in /home/user_skills/*.zip; do
    [ -f "$f" ] || continue
    found_user=1
    name=$(basename "$f" .zip)
    size=$(du -sh "$f" | cut -f1)
    marker=""
    [ -f "/home/user_skills/.${name}.usermark" ] && marker=" (tem .usermark — modificada pelo usuário)"
    printf "  %-30s %s%s\n" "$name" "$size" "$marker"
  done
  if [ "$found_user" = "0" ]; then
    echo "  (nenhum zip encontrado)"
  fi
else
  echo "  /home/user_skills/ não existe"
fi

hdr "[5] AGENT-BROWSER SKILLS (subskills)"
if command -v agent-browser >/dev/null 2>&1; then
  agent-browser skills list 2>/dev/null | grep -v "^$" | sed 's/^/  /' | head -15
else
  echo "  agent-browser não disponível"
fi

hdr "[6] CLI PLUGINS (/usr/local/bin/)"
for c in z-ai z-ai-generate agent-browser bun bunx uv uvx tectonic; do
  p=$(command -v "$c" 2>/dev/null) && {
    # z-ai e z-ai-generate não suportam --version; extrair versão do package.json
    if [ "$c" = "z-ai" ] || [ "$c" = "z-ai-generate" ]; then
      v="z-ai-web-dev-sdk $(grep '"version"' /home/z/.bun/install/global/node_modules/z-ai-web-dev-sdk/package.json 2>/dev/null | tr -d ' ,"' | cut -d: -f2)"
    else
      v=$("$c" --version 2>&1 | head -1 | cut -c1-50)
    fi
    printf "  %-20s %s\n" "$c" "$v"
  } || printf "  %-20s AUSENTE\n" "$c"
done

hdr "[7] SDK Z-AI ENDPOINTS"
if [ -f /home/z/.bun/install/global/node_modules/z-ai-web-dev-sdk/dist/index.d.ts ]; then
  echo "Pacote: z-ai-web-dev-sdk"
  echo "Versão: $(grep '"version"' /home/z/.bun/install/global/node_modules/z-ai-web-dev-sdk/package.json | tr -d ' ,"' | cut -d: -f2)"
  echo ""
  echo "Subcomandos CLI (10):"
  z-ai --help 2>&1 | grep -E "^  [a-z]" | head -10 | sed 's/^/  /'
else
  echo "  SDK não encontrado"
fi

hdr "[8] MCP (no venv Python)"
python3 -c "
import importlib.metadata as m
for pkg in ('mcp', 'fastmcp'):
  try: print(f'  {pkg}: {m.version(pkg)}')
  except Exception: print(f'  {pkg}: não instalado')
" 2>/dev/null

hdr "[9] CONFIG Z-AI (/etc/.z-ai-config)"
if [ -f /etc/.z-ai-config ]; then
  python3 -c "
import json
c = json.load(open('/etc/.z-ai-config'))
print(f'  chaves: {list(c.keys())}')
print(f'  baseUrl host: {c.get(\"baseUrl\",\"\").split(\"/\")[2]}')
print(f'  apiKey: {c.get(\"apiKey\",\"<none>\")[:8]}...')
print(f'  token len: {len(c.get(\"token\",\"\"))} chars')
" 2>/dev/null
else
  echo "  /etc/.z-ai-config não encontrado"
fi

SEP
echo "FIM DO INVENTÁRIO DE SKILLS — $(date '+%F %T %Z')"

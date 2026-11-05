# `start.sh` — Script de Boot do Sandbox Z.AI

> Análise baseada no `start.sh` real (`/start.sh`, 570 linhas) e na versão enviada pelo usuário (`upload/start.sh`, 421 linhas — versão anterior sem suporte a USER_MODE).

## O que é

Script Bash executado como PID 2 (após `tini` ser PID 1) que inicializa o container do sandbox. Roda como **root** durante o boot; o shell do usuário (`z`) é aberto depois via `su z -c bash`.

## Localização

```
/start.sh          (no container, root:root, executável)
```

Não confunda: o `start.sh` é diferente dos seus scripts em `my-project/`. É código da plataforma, **imutável** para o usuário `z`.

## Ciclo de boot (etapas medidas em `/tmp/boot-timeline.log`)

```
1. Project initialization check          (~0s)   — decide FRESH vs RESTORE
2. Extracting official skills            (~1s)   — paralelo -P 4 dos zips
3. Rewriting lockfile registry           (~0s)   — [versão nova]
4. Setting permissions                    (~0s)
5. Restoring zcode state                 (~0s)   — [versão nova]
6. Loading z user profile                (~0s)
7. Git setup                              (~0s a 60s)  — init/commit se FRESH
8. Z.ai config setup                      (~0s)   — escreve /etc/.z-ai-config (444)
9. Starting ZAI service                  (background, uvicorn em :12600)
10. Waiting for ZAI service               (~5s)   — health check
11. Starting Caddy server                 (foreground, :81)  — processo final
```

Total: **~6s até serviços prontos** (medido em sandbox limpo).

## Branch FRESH vs RESTORE

```bash
SYNC_DIR=/home/sync
ARCHIVE="$SYNC_DIR/repo.tar"

if [ ! -f "$ARCHIVE" ]; then
  # BRANCH FRESH — primeiro boot de um chat novo
  echo "DATABASE_URL=file:..." > /home/z/my-project/.env
  mkdir -p /home/z/my-project/{download,skills}
  # Cria .gitignore e faz git init/commit
else
  # BRANCH RESTORE — boot subsequente
  find /home/z/my-project -mindepth 1 -maxdepth 1 \
    ! -path "/home/z/my-project/upload" -exec rm -rf {} +
  tar xf "$ARCHIVE" -C /home/z/my-project \
    --exclude='./upload' --exclude='upload'
fi
```

**Regras derivadas:**

1. **`/home/z/my-project/upload/` é mount OSS** — preservado em ambos os branches.
2. **`/home/sync/repo.tar` é o snapshot do estado anterior** — restaurado a cada boot não-FRESH.
3. **O tar exclui `./upload`** — não entra no snapshot (é mount próprio).

## Re-extração das skills oficiais (PARALELO)

```bash
# Filtra por /home/official_skills/stages.yaml
allowed_skills=$(grep -E '^\s+-\s+\S' /home/official_skills/stages.yaml | ...)

# Para cada zip em /home/official_skills/*.zip:
#   - se NÃO está em allowed_skills: skip
#   - senão: copia para /tmp e unzip -qq -o para /home/z/my-project/skills/

# Paralelo: xargs -P 4 (4 workers)
# Razão do cp-then-unzip: OSS layer tem alta latência em random small reads
```

**Implicações críticas:**

- **`/home/z/my-project/skills/` é sobrescrito a cada boot** — ferramentas customizadas lá são perdidas
- **`stages.yaml` decide quais skills são extraídas** — pode variar entre chats
- Use **`tools/`** para suas ferramentas (não é tocado pelo boot)

## Git setup (auto-heal do `.gitignore`)

```bash
# .gitignore NARROW — apenas skills/ e node_modules/
cat > /home/z/my-project/.gitignore <<'EOF'
skills/
node_modules/
EOF
```

**Por que tão restritivo?** Em 09/06/2026, um commit `b407e6a` adicionou `upload/`, `download/`, `db/` etc. ao `.gitignore`. Isso fez o `ripgrep --files` (usado pelo handler `git ls-tree` da plataforma) **esconder** esses diretórios da árvore visível ao agente. Resultado: o agente não via `upload/` nem `download/`. O auto-heal detecta a versão larga (pela tripla `upload/`+`download/`+`db/`) e reescreve para a versão narrow. Roda uma vez por instância afetada.

**Incidente histórico:** `agent-claw-cb40fa5b` boot-loopou **36 vezes em 12,5h** por causa disso. Sem o `.gitignore` narrow ANTES do `git add .`, o git hasha 10k+ arquivos das skills, estoura o orçamento de 60s, recebe SIGTERM e o FC reconstrói o container. Loop infinito.

**Orçamentos de git:**

- `git init`, `git add .`, `git commit` — cada um com `timeout --kill-after=10s 60s`
- Total: 60s por etapa → se estourar, EXIT trap dispara e loga `/tmp/boot-timeline.log`

## Config API (`/etc/.z-ai-config`)

```bash
echo '{"baseUrl": "https://internal-api.z.ai/v1", "apiKey": "Z.ai"}' > /etc/.z-ai-config
chmod 444 /etc/.z-ai-config
```

- Escrito pelo `start.sh` **com permissões 444 (read-only para todos)** — `chattr +i` não é usado, mas o `chmod 444` impede escrita por usuário normal
- O `apiKey: "Z.ai"` é **placeholder** (4 chars) — a auth real usa `token` (JWT injetado depois do boot)
- **Em runtime**, a plataforma injeta chaves extras (`chatId`, `token`, `userId`, `diskRetire`, `stage`)
- **7 chaves confirmadas** ao vivo: `baseUrl`, `apiKey`, `chatId`, `diskRetire`, `stage`, `token`, `userId`

## Serviços iniciados

### ZAI Control (background, root)

```bash
(cd /app && UV_CACHE_DIR=/root/.cache/uv uv run main.py) &
# Roda como root, com cache uv separado do usuário z
# uvicorn/FastAPI em :12600 (localhost)
```

### Caddy (foreground, root, processo final)

```bash
exec caddy run --config /app/Caddyfile --adapter caddyfile
# Substitui o PID do shell — vira o processo principal do container
# Escuta em :81 (proxy principal / ingress)
```

### Projeto Bun/Next.js (background, condicional)

```bash
# Fluxo 1: se existe /home/z/my-project/.zscripts/dev.sh
sudo -u z bash /home/z/my-project/.zscripts/dev.sh &

# Fluxo 2: senão, se existe package.json
sudo -u z bun install
sudo -u z bun run db:push
sudo -u z bun run dev    # porta 3000
# + mini-services/ (cada subdir com package.json roda em background)
```

## USER_MODE (versão nova, não na versão enviada)

```bash
if [ "${SANDBOX_MODE:-}" = "user" ]; then
  USER_MODE=true
  mkdir -p /home/z/chats /home/z/.chat-state /home/z/.chat-tmp
  # Cada chat tem projeto em /home/z/chats/chat-{id}
  # .chat-state tem tokens (700, só root lê)
fi
```

A versão enviada pelo usuário (421 linhas) **não tem** esse bloco. A versão atual do container (570 linhas) tem. É a única diferença estrutural maior entre as duas — o restante é idêntico.

## boot-timeline.log

```
[BOOT] start.sh entered at 2026-11-04T15:14:41Z uptime=5.40s
[BOOT] 2026-11-04T15:14:41Z start step="Project initialization check" uptime=5.41s
[BOOT] 2026-11-04T15:14:41Z end   step="Project initialization check" duration=0s uptime=5.43s
...
[BOOT] 2026-11-04T15:14:48Z start step="Starting Caddy server" uptime=11.81s
```

- **`uptime=5.40s` no entry** = 5.4s passaram entre o container iniciar e o `start.sh` rodar — esse overhead é da plataforma FC (image pull, mount setup)
- **Cada etapa loga start e end com timestamp + uptime**
- **Disponível em `/tmp/boot-timeline.log`** durante a sessão

## Como inspecionar

```bash
# Ver a timeline completa do boot ATUAL:
cat /tmp/boot-timeline.log

# Ver o start.sh (imutável, root-only read para z):
cat /start.sh | head -50

# Confirmar que /etc/.z-ai-config foi criado por ele:
ls -la /etc/.z-ai-config
# esperado: -r--r--r-- 1 root root

# Ver os serviços iniciados:
ps aux | grep -E "caddy|main.py|uv run" | grep -v grep
```

## Regras práticas para IAs

1. **Nunca tente modificar `/start.sh`** — é root-only e imagem-base; alterações morrem no reset.
2. **Se quiser rodar código customizado no boot**, use `/home/z/my-project/.zscripts/dev.sh` — o `start.sh` executa ele como `z` em background.
3. **`/etc/.z-ai-config` é reescrito a cada boot** — não tente editá-lo. Se precisar injetar config, faça no `dev.sh`.
4. **O `repo.tar` é gerado pelo pre-stop** (script fora do `start.sh`, em `/app/prestop.py`), mas o `start.sh` o lê.
5. **`skills/` será sempre sobrescrito** por zips oficiais no boot — use `tools/` para suas ferramentas.
6. **Orçamento de boot: 60s por etapa de git, 120s de health check** — mantenha `repo.tar` enxuto.
7. **Caddy é o PID 1 efetivo** após `exec` — derrubar Caddy derruba o container.

## Diferenças entre a versão enviada e a versão real

| Característica | Versão enviada (421 linhas) | Versão real atual (570 linhas) |
|---|---|---|
| USER_MODE / sandbox mode | ❌ ausente | ✅ presente (checa `SANDBOX_MODE=user`) |
| Diretórios `/home/z/chats/`, `/home/z/.chat-state/`, `/home/z/.chat-tmp/` | ❌ não criados | ✅ criados em USER_MODE |
| Lockfile registry rewrite | ❌ ausente | ✅ presente como etapa separada |
| zcode state restoration | ❌ ausente | ✅ presente como etapa separada |
| ROOT_CONTROL_PLANE_PATH | ❌ ausente | ✅ definido no topo |

**Conclusão:** A versão enviada é uma versão mais antiga (sem suporte a multi-chat por usuário). A versão real tem features adicionais. Para análise do **ciclo de persistência**, ambas são equivalentes — o bloco `repo.tar` é idêntico.

---

*Análise realizada em 04/11/2026 por leitura direta do `/start.sh` (570 linhas) e comparação com a versão enviada (421 linhas). Para reauditar, rode: `cat /start.sh` e `cat /tmp/boot-timeline.log`.*

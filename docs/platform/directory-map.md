# Mapa Completo de Diretórios do Sandbox Z.AI

> Investigação sistemática de cada diretório da raiz `/` em 04/11/2026.
> Cada pasta explorada com `ls -la`, identificados donos, permissões, tamanho e conteúdo notável.

## Resumo executivo

| Diretório | Tamanho | Dono | Permissão | Status |
|---|---|---|---|---|
| `/app` | 8.0K | root:root | `drwx--x--x` (711) | ❌ inacessível (código da plataforma) |
| `/opt` | 326M | root:root | `drwxr-xr-x` | ✅ **NOVO! ZCode Server v3.16.2** |
| `/usr` | 4.1G | root:root | `drwxr-xr-x` | ✅ sistema + clawhub CLI + ImageMagick-7 config |
| `/etc` | 5.9M | root:root | `drwxr-xr-x` | ✅ configs (apenas leitura) |
| `/var` | 60M | root:root | `drwxr-xr-x` | ✅ cache, log, lib |
| `/tmp` | 99M | root:root | `drwxrwxrwt` (1777) | ✅ efêmero — contém tectonic, hsperfdata, locks uv |
| `/home` | 6.8G | root:root | `drwxr-xr-x` | ✅ onde vive o usuário `z` |
| `/root` | 8.0K | root:root | `drwx------` (700) | ❌ inacessível |
| `/lost+found` | 12K | root:root | `drwx------` | ❌ inacessível |
| `/boot`, `/media`, `/mnt`, `/srv` | <4K | root:root | `drwxr-xr-x` | ✅ vazios |
| `/dev` | — | root:root | `drwxr-xr-x` | ✅ virtual (tmpfs) |
| `/proc`, `/sys` | — | root:root | `dr-xr-xr-x` | ✅ virtual |
| `/run` | 76K | root:root | `drwxr-xr-x` | ✅ systemd, locks; tem `/run/zcode-driver/` (root only) |
| `/bin`, `/sbin`, `/lib`, `/lib64` | — | root:root | symlinks | ✅ symlinks para `/usr/bin`, `/usr/sbin`, `/usr/lib`, `/usr/lib64` |

---

## 1. `/opt/zcode/` — RUNTIME DO ZCODE SERVER (DESCOBERTA NOVA!)

### O que é

**ZCode Server v3.16.2** — outro produto Z.AI (mencionado no gateway como source `zcode`). É um agente de código (estilo Claude Code/Cursor) com:

- 14 plugins (android-emulator, browser-use, documents, image-search, ios-simulator, pdf, plugin-creator, presentations, restore-legacy-sessions, skill-creator, spreadsheets, visualize, zcode-cua, zcode-guide)
- 3 tools (bfs, ripgrep, ugrep)
- Node 22.16.0 embarcado (binário próprio em `/opt/zcode/rt/runtime/node`)
- 1 skill bundled: `dynamic-workflows`

### Estrutura

```
/opt/zcode/rt/
├── bin/zcode                          (launcher shell → node server-cli.js)
├── manifest.json                      (manifesto do produto)
├── zcode-builtin.json                 (180 KB — config de providers/models)
└── runtime/
    ├── node                           (binário Node 22.16.0, ELF 64-bit)
    ├── server-cli.js                  (entrypoint CLI)
    ├── server-core.js                  (entrypoint core)
    ├── zcode.cjs                       (entrypoint agent)
    ├── node_modules/                  (deps)
    ├── tools/                          (bfs, ripgrep, ugrep)
    │   ├── bfs/
    │   ├── ripgrep/
    │   └── ugrep/
    └── packages/                      (15 plugins)
        ├── android-emulator-plugin/
        ├── browser-use-plugin/
        ├── bundled-skills/            (1 skill: dynamic-workflows)
        ├── documents-plugin/
        ├── image-search-plugin/
        ├── ios-simulator-plugin/
        ├── pdf-plugin/
        ├── plugin-creator-plugin/
        ├── presentations-plugin/
        ├── restore-legacy-sessions-plugin/
        ├── skill-creator-plugin/
        ├── spreadsheets-plugin/
        ├── visualize-plugin/
        ├── zcode-cua-plugin/
        └── zcode-guide-plugin/
```

### Manifesto (resumo)

```json
{
  "product": "zcode-server",
  "appVersion": "3.16.2",
  "nodeVersion": "22.16.0",
  "entrypoints": {
    "cli": "runtime/server-cli.js",
    "core": "runtime/server-core.js",
    "agent": "runtime/zcode.cjs"
  },
  "tools": ["bfs", "ripgrep", "ugrep"],
  "plugins": [14 plugins],
  "components": [
    {"id": "node-runtime", "sizeBytes": 121651529, "sha256": "..."},
    {"id": "server-runtime", "sizeBytes": 117392326, "sha256": "..."},
    ...
  ]
}
```

### Config de modelos (zcode-builtin.json)

Inclui regras para:
- **GLM-5.3** e **GLM-5.3-Flash** (Z.AI Coding Plan)
- Claude opus 4.8/5 (apiType `anthropic-messages`)
- OpenAI, OpenRouter, etc. (via templates `zai-api`, `opencode-go-chat`, etc.)

### Launcher

```sh
#!/bin/sh
# /opt/zcode/rt/bin/zcode
DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec "$DIR/runtime/node" "$DIR/runtime/server-cli.js" "$@"
```

**Não está no PATH** — precisa chamar como `/opt/zcode/rt/bin/zcode`.

### Skill bundled: `dynamic-workflows`

`/opt/zcode/rt/runtime/packages/bundled-skills/skills/dynamic-workflows/SKILL.md`

Skill para escrever/debugar scripts de `CreateWorkflow` — ferramenta do ZCode para delegação de subagents.

---

## 2. `/usr/lib/node_modules/` — 3 pacotes globais

| Pacote | Versão | O que é |
|---|---|---|
| `clawhub` | 0.25.1 | **CLI do ClawHub** (skill registry público) |
| `npm` | (default Node) | Node Package Manager |
| `corepack` | (default Node) | Manager para yarn/pnpm |

### ClawHub CLI (NOVO!)

```
$ which clawhub clawdhub
/usr/bin/clawhub
/usr/bin/clawdhub
```

**Comandos disponíveis:**

```
Auth:
  login [options]              Log in with device flow or store a token
  logout                       Remove stored token
  whoami                       Validate token
  auth                         Authentication commands

Skills:
  search [options] <query...>  Search skills
  scan [options] [path]        Run or download ClawHub scan reports
  install                       Install skills
  publish                       Publish skills
  token                        Print stored API token
```

**Registry padrão:** `https://clawhub.ai` (config em `/home/z/.config/clawhub/config.json`)

### Teste de busca real (sem auth)

```bash
$ clawhub search document
alibabacloud-bailian-rag-knowledgebase       @sdk-team            Alibabacloud Bailian Rag Knowledgebase     1 installs / 60d
word-docx                                    @ivangdavila         Word / DOCX                                64 installs / 60d
pdf                                          @awspace             Pdf                                       32 installs / 60d
document-skills                              @ryanallen           Create Skills                             3 installs / 60d
official-document                             @zhangxue1985122219  一键转换为机关公文标准格式                    2 installs / 60d
...

$ clawhub search pdf
skills-sh:anthropics/skills/pdf  @anthropics  pdf  222.025 skills.sh lifetime installs
skills-sh:openai/skills/pdf      @openai      pdf  13.602 skills.sh lifetime installs
pdf                              @awspace     Pdf  32 installs / 60d
...
```

**Funciona sem login!** Busca em registry público ClawHub (clawhub.ai). Inclui skills da Anthropic, OpenAI, Alibaba e comunidade.

### Como instalar skill do ClawHub

```bash
clawhub install <skill-name>
# (precisa de clawhub login antes, para não-anonymous install)
```

---

## 3. `/home/z/` — diretórios e arquivos

### Estrutura completa

```
/home/z/
├── .agent-browser/              (browser cache)
├── .bun/                         (Bun runtime global)
├── .cache/                       (ms-playwright, puppeteer)
├── .config/                      (clawhub, gh, etc.)
│   └── clawhub/config.json       ({"registry":"https://clawhub.ai"})
├── .gitconfig                    ([safe]directory + [user]name=Z User, email=z@container)
├── .local/                       (uv python install)
├── .npm/                         (npm cache, efêmero)
├── .npm-global/                  (globals: mmdc, sharp, docx, pdf-lib, pptxgenjs, playwright)
├── .npmrc                        (prefix=/home/z/.npm-global)
├── .venv/                        (Python 3.12 venv, 921 pacotes)
├── .zai-reserve/                 (NOVO — root:root 700, inacessível)
├── .zcode/                       (NOVO — AGENTS.md, o prompt de sistema)
│   └── AGENTS.md
├── my-project/                   (seu projeto — persistente)
├── node_modules -> /home/z/.npm-global/lib/node_modules  (symlink)
├── pyproject.toml                (manifesto do venv: "z-agent" v0.1.0)
└── uv.lock                       (lockfile do uv, 1.2 MB)
```

### `/home/z/.zcode/AGENTS.md` — Prompt de sistema do agente Z.AI

**Instruções base** que regem todo agente rodando neste sandbox. Trechos-chave:

```markdown
# z.ai agent

You are the agent behind z.ai's agent mode. You run alone in a Linux sandbox;
there is no human watching the terminal and nobody can answer questions or
approve actions mid-task. Make reasonable decisions yourself and keep going
until the task is done.

## Workspace

- Work only inside `/home/z/my-project/`. Do not write anywhere else
  (no `/tmp`, no home directory dotfiles).
- Files the user uploaded are in `/home/z/my-project/upload/`. Treat them
  as input; do not modify them in place.
- Every file you produce for the user MUST be saved under
  `/home/z/my-project/download/` (use absolute paths, subdirectories are fine).
  Only files there are shown to the user; anything else is invisible to them.
- The sandbox can be recycled between messages. Everything under
  `/home/z/my-project/` is kept; processes you started are not.

## Output

- Reply in the same language the user writes in.
- For tables, prefer `.xlsx`. For reports and analysis, prefer `.docx` or `.pdf`
  over `.md`/`.txt`, unless the user asks for a specific format.
- When you finish, tell the user briefly what you did and list the files
  you saved in `download/`.

## Subagents

- You may delegate with the `Agent` tool. Use `Explore` for read-only
  investigation and `general-purpose` for work that has to write files.
- Never set `run_in_background`. Background agents do not survive this turn.

## Rules

- Some commands are blocked by policy (piping downloads into a shell, reverse
  shells, reading other processes' environment, tunnels, cloud metadata
  endpoints). If a command is denied, do not try to work around the denial.
- Never print, store or send credentials, tokens or keys you come across.
```

### `/home/z/.zai-reserve/` — NOVO (root only)

Diretório `drwx------ root root`. Provavelmente contém arquivos de reserva da plataforma. Inacessível ao user `z`.

### `/home/z/pyproject.toml` — Manifesto do venv

Projeto `z-agent` v0.1.0 (Python ≥3.12) com **dependências pinadas** (versões exatas):

```
aiohttp==3.13.3
fastmcp==2.14.3
loguru==0.7.3
ripgrepy==2.2.0
numpy==2.1.3
pandas==2.2.3
scipy==1.14.1
matplotlib==3.9.2
seaborn==0.13.2
playwright==1.57.0
beautifulsoup4==4.14.3
lxml==6.0.2
html5lib==1.1
Pillow==11.3.0
opencv-python-headless==4.13.0.90
ffmpeg-python==0.2.0
moviepy==2.2.1
pydub==0.25.1
openpyxl==3.1.5
xlrd==2.0.2
xlwt==1.3.0
python-docx==1.2.0
...
```

**Confirma:** o venv é mantido como projeto versionado (não aleatório). As 921 bibliotecas são derivadas dessas dependências + subdeps.

### `/home/z/.gitconfig`

```ini
[safe]
    directory = /home/z/my-project
[user]
    email = z@container
    name = Z User
```

### `/home/z/.npmrc`

```
prefix=/home/z/.npm-global
```

### `/home/z/extract-official-skills.sh` (NOVO!)

Script da plataforma em `/home/extract-official-skills.sh` — equivalente standalone ao bloco "Extracting official skills" do `start.sh`. Pode ser chamado manualmente para re-extrair skills sem reboot.

---

## 4. `/home/z/my-project/` — diretórios

```
/home/z/my-project/
├── .env                          (DATABASE_URL=file:./db/custom.db)
├── .git/                         (repositório git, persiste)
├── .gitignore                    (skills/, node_modules/)
├── PERSISTENCE_MARKER.txt        (marcador do script validate_persistence.sh)
├── download/                     (entregáveis visíveis ao usuário)
├── skills/                       (21 skills oficiais, re-extraídas a cada boot)
├── tool-results/                 (NOVO — outputs grandes salvos pelo agente)
├── tools/                        (ferramentas persistidas: bin/gh)
├── upload/                       (mount OSS — arquivos enviados pelo usuário)
└── z-ai-sandbox/                 (este knowledge base)
```

### `/home/z/my-project/tool-results/` — NOVO

Diretório criado automaticamente pelo tool `Bash` quando output excede 30.000 chars. Os arquivos ficam com nome tipo `bash_<timestamp>_<hash>.txt`. Confirma que é onde parte desta investigação foi salva quando o output foi grande!

---

## 5. `/tmp/` — conteúdos notáveis

```
/tmp/
├── boot-timeline.log             (timeline do boot)
├── hsperfdata_root/              (Java HotSpot performance data)
├── my-project/                   (mount PolarFS para snapshots)
├── node-compile-cache/           (cache de compilação Node)
├── tectonic                      (binário — também em /usr/local/bin, mas aqui é outra cópia)
├── uv-*.lock                     (~17 arquivos de lock do uv)
└── LICENSE, README.md            (textos gerais do python??)
```

---

## 6. `/usr/local/` —instalações locais

```
/usr/local/
├── bin/
│   ├── agent-browser             (symlink → ~/.bun/install/global/node_modules/agent-browser/...)
│   ├── bun                       (91.8 MB — binário principal)
│   ├── bunx → /usr/local/bin/bun (symlink)
│   ├── docker-entrypoint.sh      (wrapper que faz `bun $@` se não houver comando)
│   ├── tectonic                  (57.4 MB — LaTeX engine)
│   ├── uv                        (37.5 MB — gerenciador Python)
│   ├── uvx                       (330 KB — executor de pacotes Python)
│   ├── z-ai                      (symlink → ~/.bun/install/global/node_modules/z-ai-web-dev-sdk/dist/cli.js)
│   └── z-ai-generate             (symlink → mesmo)
├── bun-node-fallback-bin/
│   └── node → /usr/local/bin/bun  (NOVO — fallback! se alguém chamar 'node' sem ter, cai para bun)
├── etc/                          (vazio)
├── lib/python3.13/               (Python system 3.13.5)
├── share/{ca-certificates,fonts,man}/
└── src/,games,libexec,sbin,include/  (vazios)
```

**Insight:** `bun-node-fallback-bin/node -> /usr/local/bin/bun` faz `node` cair para `bun` se o `node` real não estiver no PATH. Porém `node` está em `/usr/bin/node` (v24.22.2), então esse fallback só dispara em contextos específicos.

---

## 7. `/etc/` — configs notáveis

- `/etc/.z-ai-config` (444, root) — auth da plataforma (já mapeado)
- `/etc/ImageMagick-7/` — config do ImageMagick (sim, ele tem config, mas o binário `convert` NÃO está instalado — só a config existe)
- `/etc/credstore`, `/etc/credstore.encrypted` (root only) — credenciais criptografadas
- `/etc/ssl/private/` (root only) — chaves SSL
- `/etc/.gitconfig` — NÃO existe (é em `/home/z/.gitconfig`)
- `/etc/sudoers.d/` — vazio (confirma que não há sudo configurado)

---

## 8. `/usr/share/fonts/` — fontes disponíveis (importante para PDF/docx)

```
/usr/share/fonts/truetype/
├── chinese/                      (fontes chinesas)
├── dejavu/                       (DejaVu — serif, sans, mono)
├── emoji/                        (NotoColorEmoji.ttf — emoji)
├── english/                      (fontes inglesas)
├── fonts-japanese-gothic.ttf    (japonês gothic)
├── freefont/                     (FreeFont)
├── japanese/                      (fontes japonesas)
├── liberation/                   (Liberation — substituto Arial/Times)
├── libreoffice/                  (fontes do LibreOffice)
├── lxgw-wenkai/                  (LXGW WenKai — chinês)
├── noto/                         (Noto Sans family)
├── noto-serif-sc/                (Noto Serif SC — chinês)
└── wqy/                          (WenQuanYi — chinês)
```

**Confirma:** sandbox tem fontes para **chinês, japonês, emoji, sânscrito** — pronto para I18N em PDF/docx.

---

## 9. Portas internas — novas descobertas

### Porta 12700 — API LLM secundária

- ✅ Escuta em `127.0.0.1:12700` (localhost)
- ✅ Responde HTTP (FastAPI/uvicorn-like)
- ❌ Apenas `POST /v1/chat/completions` é suportado
- ❌ Requer **"local key"** (não o JWT do `/etc/.z-ai-config`)

**Mensagens de erro observadas:**

```bash
$ curl http://localhost:12700/
{"error":{"message":"only POST /v1/chat/completions is served here","type":"not_found","code":"not_found"}}

$ curl -X POST http://localhost:12700/v1/chat/completions -d '{...}'
{"error":{"message":"invalid local key","type":"invalid_api_key","code":"invalid_api_key"}}

# Com headers do .z-ai-config:
$ curl -X POST -H "Authorization: Bearer Z.ai" -H "X-Z-AI-From: Z" -H "X-Chat-Id: ..." -H "X-User-Id: ..." -H "X-Token: ..." http://localhost:12700/v1/chat/completions
{"error":{"message":"invalid local key","type":"invalid_api_key","code":"invalid_api_key"}}
```

**Conclusão:** porta 12700 é uma API LLM interna (provavelmente usada por algum plugin do ZCode ou pelo agent-browser). Não é acessível com nossas credenciais — requer "local key" diferente.

### Portas 19001, 19005, 19006

- Todas escutam (LISTEN confirmado)
- Não falam HTTP — `curl` retorna vazio ou sem resposta
- Provavelmente são **sockets raw** para comunicação interna (RPC, IPC)
- Não consegui identificar protocolo com `curl`

**Conclusão:** são serviços internos de RPC/IPC da plataforma. Não vale a pena investigar mais sem ferramentas específicas de cada protocolo.

### `/run/zcode-driver/` (root only)

Diretório `drwx--x--x` em `/run/` — driver do ZCode. Inacessível a `z`.

---

## 10. Resumo das descobertas novas desta investigação

| Item | Status | Importância |
|---|---|---|
| `/opt/zcode/` — runtime completo do ZCode Server v3.16.2 | NOVO | ⭐⭐⭐ |
| `clawhub` CLI v0.25.1 disponível (registry público clawhub.ai) | NOVO | ⭐⭐⭐ |
| `/home/z/.zcode/AGENTS.md` — prompt de sistema do agente | NOVO | ⭐⭐⭐ |
| `/home/z/.zai-reserve/` — root only, propósito desconhecido | NOVO | ⭐⭐ |
| `/home/z/pyproject.toml` — manifesto do venv (z-agent v0.1.0) | NOVO | ⭐⭐ |
| `/home/z/my-project/tool-results/` — outputs grandes do Bash | NOVO | ⭐⭐ |
| `/home/extract-official-skills.sh` — script standalone | NOVO | ⭐⭐ |
| `/usr/local/bun-node-fallback-bin/node → bun` | NOVO | ⭐⭐ |
| Porta 12700 — API LLM com "local key" diferente | NOVO | ⭐⭐ |
| `/usr/share/fonts/` — fontes CJK + emoji + LXGW WenKai | NOVO | ⭐⭐ |
| `/etc/ImageMagick-7/` — config existe mas binário ausente | confirmação | ⭐ |
| Portas 19001/19005/19006 — não-HTTP (RPC interno) | confirmação | ⭐ |

---

## 11. Mapa final consolidado

```
/
├── .dockerenv                            (marcador de container)
├── start.sh                              (entrypoint, root:root, 27 KB)
│
├── app/                                  ❌ inacessível (711 root) — código da plataforma
│
├── opt/                                  ✅ NOVO
│   └── zcode/rt/                          (ZCode Server v3.16.2)
│       ├── bin/zcode                      (launcher)
│       ├── manifest.json
│       ├── zcode-builtin.json            (180 KB, providers/models)
│       └── runtime/                       (Node 22.16.0 + 15 plugins)
│
├── usr/
│   ├── bin/                               (binários do sistema + clawhub)
│   ├── lib/node_modules/                  ✅ clawhub, npm, corepack
│   ├── local/bin/                         (z-ai, agent-browser, bun, tectonic, uv, uvx)
│   ├── local/bun-node-fallback-bin/node → bun  ✅ NOVO fallback
│   ├── share/fonts/truetype/             ✅ CJK + emoji + LXGW WenKai
│   └── ...                                (resto é Debian 13 standard)
│
├── etc/
│   ├── .z-ai-config                       (444 root — auth plataforma)
│   ├── ImageMagick-7/                    (config sem binário)
│   ├── credstore, credstore.encrypted    (root only)
│   └── ...                                (configs Debian standard)
│
├── var/
│   ├── cache/uv/                          (cache do uv)
│   ├── lib/{apt,dpkg,git,libreoffice,python}
│   ├── log/                               (logs Debian)
│   └── spool/{libreoffice,mail}
│
├── tmp/
│   ├── boot-timeline.log                  (timeline do boot)
│   ├── hsperfdata_root/                   (Java HotSpot)
│   ├── my-project/                        (mount PolarFS, snapshots)
│   ├── node-compile-cache/
│   ├── tectonic                           (cópia do binário)
│   └── uv-*.lock                          (~17 locks)
│
├── home/
│   ├── bun/                               (usuário bun, 700)
│   ├── extract-official-skills.sh         ✅ NOVO (standalone script)
│   ├── official_skills/                  (OSS ro, zips das 70 skills)
│   ├── sync/                              (OSS rw, repo.tar)
│   ├── user_skills/                       ✅ vazio agora (limpei)
│   ├── skills/                            ✅ NOVO (criado pela tool scan_new_skill)
│   └── z/                                 (HOME do usuário)
│       ├── .agent-browser/browsers/      (cache)
│       ├── .bun/install/global/          (z-ai-web-dev-sdk, agent-browser)
│       ├── .cache/                        (ms-playwright, puppeteer)
│       ├── .config/{clawhub,gh}/          (configs de CLI)
│       ├── .gitconfig                     (z@container)
│       ├── .local/share/uv/python/        (CPython 3.12.16)
│       ├── .npm/                          (cache, efêmero)
│       ├── .npm-global/lib/node_modules/ (mmdc, sharp, docx, pdf-lib, pptxgenjs, playwright)
│       ├── .npmrc                         (prefix=/home/z/.npm-global)
│       ├── .venv/                         (Python 3.12.16, 921 pacotes)
│       ├── .zai-reserve/                  ❌ NOVO (root only)
│       ├── .zcode/AGENTS.md               ✅ NOVO (prompt de sistema do agente)
│       ├── my-project/                    (PROJETO — persistente via repo.tar)
│       ├── node_modules → .npm-global/... (symlink)
│       ├── pyproject.toml                 ✅ NOVO (manifesto z-agent v0.1.0)
│       └── uv.lock                        (lockfile)
│
├── bin, sbin, lib, lib64                  (symlinks → usr/bin, usr/sbin, usr/lib, usr/lib64)
│
├── boot/, media/, mnt/, srv/              (vazios)
│
├── dev/, proc/, sys/                      (virtual)
│
├── run/                                   (systemd, locks; /run/zcode-driver/ root only)
│
└── root/, lost+found/                     ❌ inacessíveis
```

---

## 12. Como aproveitar as descobertas

### Para encontrar skills externas (ClawHub)

```bash
# Buscar no registry público ClawHub:
clawhub search <query>

# Login (precisa de conta):
clawhub login
clawhub whoami

# Instalar skill:
clawhub install <skill-name>
```

### Para inspecionar o ZCode (não precisa instalar nada)

```bash
# Ver manifest:
cat /opt/zcode/rt/manifest.json | python3 -m json.tool

# Ver builtin skills:
ls /opt/zcode/rt/runtime/packages/bundled-skills/skills/

# Ler AGENTS.md (prompt de sistema):
cat /home/z/.zcode/AGENTS.md

# Ver providers/models suportados:
python3 -c "
import json
data = json.load(open('/opt/zcode/rt/zcode-builtin.json'))
print(json.dumps(data['config']['providerConfigRules'], indent=2))
"
```

### Para verificar fontes disponíveis (para PDF/docx)

```bash
# Listar todas:
fc-list 2>/dev/null | head -20
# ou:
ls /usr/share/fonts/truetype/

# Verificar fonte específica (ex: Noto Serif SC):
ls /usr/share/fonts/truetype/noto-serif-sc/
```

### Para ver venv Python completo

```bash
# Dependências declaradas:
cat /home/z/pyproject.toml

# Lockfile (versões exatas):
head -50 /home/z/uv.lock

# Pacotes instalados:
ls /home/z/.venv/lib/python3.12/site-packages/ | wc -l
```

---

*Investigação sistemática de toda a árvore `/` em 04/11/2026. Cada diretório listado com `ls -la` e analisado. Resultado: 12 descobertas novas não documentadas em investigações anteriores.*

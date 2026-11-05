# Sandbox Z.AI — Conhecimento do Ambiente

> **Para IAs rodando dentro do sandbox Z.AI.** Tudo validado empiricamente em 04/11/2026.

## Identificação rápida

```bash
uname -r           # 5.10.134-...kangaroo.al8  (Alibaba Cloud Linux 8, Kata/KVM)
cat /etc/os-release | grep PRETTY   # Debian 13 (trixie)
id                 # uid=1001(z) — SEM sudo
nproc              # 2
free -h | head -2   # 4.1 GB total, 0 swap
```

## Hardware

| Recurso | Valor | Nota |
|---|---|---|
| CPU | 2 vCPUs Intel Xeon (model 173) | AMX + AVX-512 (acelerador IA), sem GPU |
| RAM | 4 GB (cgroup 4.294.967.296 bytes) | **Sem swap** — OOM silencioso (exit 137) |
| Disco | 9,9 GB rootfs | `df` mente: 64P/16E em PolarFS/ossfs é virtual |
| Limite | 2 cores por cpuset `0-1` | Use `make -j2` no máximo |

## Persistência — o que sobrevive a um reset

| Caminho | Persiste? | Como |
|---|---|---|
| `/home/z/my-project/**` | **Sim** | via `repo.tar` no OSS (`/home/sync/`) |
| `/home/z/my-project/upload/` | **Sim** | mount `fuse.ossfs` direto (não entra no tar) |
| `/home/sync/` | **Sim** | OSS rw 777 — abriga o `repo.tar` |
| `/home/z/my-project/skills/` | **RISCO** | re-extraído a cada boot — não use para ferramentas próprias |
| `/home/z/my-project/tools/` | **Sim** | o local seguro para ferramentas customizadas |
| `/home/z/.venv/` | **Sim** (parte da imagem) | 921 pacotes (pandas, numpy, mcp, fastmcp...) voltam no boot |
| `/home/z/.cache/` (browsers) | **Sim** (parte da imagem) | ms-playwright, puppeteer |
| `/home/z/.bun/`, `~/.npm/`, `~/.local/` | **Não** | efêmeros — reinstaláveis rapidamente |
| `/tmp/`, `/var/tmp/` | **Não** | builds e temporários |
| `/app` | Inacessível (711 root) | código da plataforma — não tente ler |

**Regra-mãe:** só `/home/z/my-project` (via `repo.tar`) e mounts OSS sobrevivem. Reset pode vir a qualquer momento.

## Arsenal pré-instalado (já vem, não instale)

| Runtime | Versão | Path |
|---|---|---|
| `python3` (default PATH) | **3.12.16** (venv, 921 pacotes) | `/home/z/.venv/bin/python3` |
| `/usr/bin/python3` (sistema) | 3.13.5 (só numpy 2.2.4) | use apenas para scripts sem deps |
| `node` | 24.22.2 | + npm 11.19.1 |
| `bun` | 1.3.14 | runtime JS da plataforma |
| `uv` | 0.13.7 | gerenciador Python rápido |
| `git` | 2.47.3 | identidade global auto-configurada |

**Atenção Python:** se `python3 -c "import pandas"` falhar, o binário do venv morreu. Restaure com `uv python install 3.12` (36 ms com cache).

### Ferramentas (validadas)

- gcc/g++ 14.2.0, make 4.4.1, autoconf 2.72 — **cmake AUSENTE**
- jq 1.7, curl/wget, tar/rsync, tini 0.19.0
- FFmpeg 7.1.5, Ghostscript 10.05.1, Tesseract 5.5.0, Pandoc 3.1.11.1 (`--pdf-engine=tectonic`)
- LibreOffice 25.2.3.2, Java 21.0.13, Tectonic 0.15.0 (LaTeX)
- **AUSENTES:** ImageMagick (`convert`), sqlite3 CLI (use `python3 -c "import sqlite3"`), xelatex (use tectonic)

### Node globals (em `~/.npm-global`)

`mmdc` 12.2.0 (mermaid-cli), `playwright` 1.57.0, `sharp` 0.35.5, `docx` 9.15.2, `pdf-lib` 1.17.1, `pptxgenjs` 4.0.1

### MCP no venv Python

- `mcp` 1.27.0 + **`fastmcp` 2.14.3** (zero instalação)
- `npx -y @modelcontextprotocol/server-everything` também funciona

## SDK z-ai (IA nativa, sem chave)

CLI: `/usr/local/bin/z-ai` — sempre disponível, auth via `/etc/.z-ai-config` (444, root).

```bash
z-ai chat --prompt "..."           # LLM (glm-4-plus)
z-ai vision --image ...            # visão (glm-5v-turbo)
z-ai image --prompt "..."          # geração imagem (40s, .png=JPEG)
z-ai tts --text "..." --format wav  # TTS (mp3 falha, só wav/pcm)
z-ai asr --audio ...               # ASR
z-ai function -n web_search -a '{"query":"...","num":3}'   # busca web (1,1s)
z-ai function -n page_reader -a '{"url":"..."}'            # leitura de página (0,5s)
```

Programático (Bun/Node):
```js
import ZAI from 'z-ai-web-dev-sdk';   // default import — `{ ZAI }` é undefined!
const zai = await ZAI.create();
await zai.chat.completions.create(body);
await zai.functions.invoke('web_search', { query, num });
```

**Variáveis `Z.AI_API_KEY` e `Z.AI_BASE_URL` NÃO existem** — auth é 100% via `/etc/.z-ai-config`.

## Rede e portas

| Porta | Serviço | Acesso |
|---|---|---|
| 81 | Caddy (proxy principal / preview) | externa |
| 12600 | uvicorn/FastAPI (ZAI Control) | localhost |
| 12700, 19001, 19005, 19006 | internos | internas |
| 3000+ | use para seus apps | — |

**Fronteiras medidas:**
- ICMP bloqueado (sem `cap_net_raw`)
- UDP funciona (DNS a 8.8.8.8)
- SMTP 25 bloqueado; 587 aberto
- Portas < 1024 falham com EACCES para user `z`
- Download rápido: ~57 MB/s
- **Geo-bloqueio**: Gemini API recusa o egress de Hong Kong

## Limites duros

| Limite | Valor | Como contornar |
|---|---|---|
| sudo/root | **nenhum** | `dpkg-deb -x`, tarball `--prefix`, pip/venv, npm/bun locais |
| Swap | 0 kB | use `-j2` no máximo; streaming em vez de arrays gigantes |
| Orçamento boot | git 60s/etapa, HC 120s | mantenha `repo.tar` enxuto (exclua upload, caches, builds, skills) |
| `/app` | 711 root | inacessível — é a plataforma |
| Background processes | imprevisíveis entre tool calls | use `.zscripts/dev.sh` para serviços |
| Max processes | 100.000 (não 1024) | normalmente sem aperto |

## Comandos diretos (diretório: `z-ai-sandbox/scripts/`)

```bash
# Diagnóstico de 30s:
bash z-ai-sandbox/scripts/quick_check.sh

# Inventário completo (~2s):
bash z-ai-sandbox/scripts/sandbox_inventory.sh

# Listar skills e plugins instalados:
bash z-ai-sandbox/scripts/list_skills.sh

# Validar persistência (simula reset via repo.tar):
bash z-ai-sandbox/scripts/validate_persistence.sh

# Restaurar venv Python se pandas falhar:
bash z-ai-sandbox/scripts/restore_venv.sh

# Testar SDK z-ai (web_search, page_reader, config):
python3 z-ai-sandbox/scripts/test_zai_sdk.py

# Testar projeto hybrid-api (16 endpoints):
bash z-ai-sandbox/scripts/test_hybrid_api.sh
```

## Regras de ouro

1. **Container é efêmero** — só `my-project/` (via repo.tar) e mounts OSS sobrevivem
2. **Sem root** — `dpkg-deb -x`, tarball `--prefix`, pip/venv, npm/bun locais
3. **Ferramentas em `tools/`, nunca em `skills/`** (re-extraída a cada boot)
4. **`make -j2` no máximo** (2 vCPU, sem swap)
5. **Portas 3000+** (`:80`/`:443` falham)
6. **Mantenha `repo.tar` enxuto** (exclua upload, caches, builds, skills)
7. **Verifique o arsenal antes de instalar** (seção acima)
8. **Segredos em `upload/`, nunca em `my-project` nem no remote URL** (entra no snapshot)
9. **Valide persistência com marcador + `diff -rq`** antes de operações arriscadas
10. **Downloads são quase grátis** (57 MB/s) — CPU e RAM são os recursos escassos

## Documentação detalhada

### Verificação de projetos (`docs/projects/`)

| Arquivo | Conteúdo |
|---|---|
| `hybrid-api.md` | Verificação do projeto `hybrid-api` (Bun + Python) — 16 endpoints, 3 bugs corrigidos |

### Análises de plataforma (`docs/platform/`)

| Arquivo | Conteúdo |
|---|---|
| `start-script.md` | Análise do `/start.sh` real (570 linhas) vs. versão enviada (421 linhas) |
| `internal-api.md` | Mapeamento da API interna (`:12600`), gateway (16 endpoints) e SDK (2 functions) |
| `zai-agent-and-mcp-deep.md` | Investigação profunda: `/v1/zai-agent/*` (turn token) + MCP interno operacional |
| `directory-map.md` | Mapa completo de todos os diretórios do sandbox — 12 descobertas novas |
| `zcode-plugins.md` | Detalhe dos 14 plugins do ZCode Server v3.16.2 — 24 skills, 9 MCP servers |
| `container-deep-investigation.md` | Processos, capabilities, cgroups, mounts, rede, /external/, 21 descobertas |

### Análises de guias externos (`docs/guides/`)

| Arquivo | Conteúdo |
|---|---|
| `coldstart-analysis.md` | Análise do `SANDBOX_GUIDE_COLDSTART.md` — 5 claims falsas, 1 bug sintático |
| `turbo-script-analysis.md` | Análise do `sandbox_turbo.sh` — 1 função PERIGOSA (`--aliases`), 1 com bug, 4 úteis |
| `turbo-guide-analysis.md` | Análise do `SANDBOX_TURBO_GUIA.md` — 11 claims falsas, 7 versões desatualizadas |

### Metodologias (`docs/methods/`)

| Arquivo | Conteúdo |
|---|---|
| `repo-documentation-method.md` | Análise do `GUIA_GERADOR_DOCUMENTACAO.md` — metodologia genérica, aplicável ao sandbox |

### Skills e plugins (`docs/skills/`)

| Arquivo | Conteúdo |
|---|---|
| `catalog.md` | Catálogo completo: 21 skills instaladas, 70 oficiais, 13 stages, 9 subskills agent-browser, MCP |
| `finance-skill-analysis.md` | Análise da skill `finance`: Yahoo Finance público funciona direto do sandbox (com User-Agent), LLM alucina dados, skill oficial via RapidAPI requer registro admin |

## Projetos no repositório (`projects/`)

| Projeto | Local | Status |
|---|---|---|
| `hybrid-api` (Bun + Python) | `projects/hybrid-api/` | ✅ 16/16 testes passando, 3 bugs corrigidos |
| `php-runner-v1.0` (PHP + Composer + PHPUnit + PHPStan) | `projects/php-runner-v1.0/` | ✅ Skill instalando PHP 8.5.12, Composer 2.11.1, PHPUnit 13.4.6, PHPStan 2.3.5 |

## Mapa final da pasta `z-ai-sandbox/`

```
z-ai-sandbox/
├── README.md                                (este arquivo)
├── docs/
│   ├── platform/
│   │   ├── start-script.md                  (análise do /start.sh)
│   │   ├── internal-api.md                  (API interna + gateway + SDK mapeados)
│   │   ├── zai-agent-and-mcp-deep.md        (zai-agent + MCP operacional via JSON-RPC)
│   │   ├── directory-map.md                 (mapa de TODOS os diretórios — 12 descobertas)
│   │   ├── zcode-plugins.md                 (14 plugins do ZCode — 24 skills, 9 MCP servers)
│   │   └── container-deep-investigation.md  (processos, cgroups, capabilities, rede, /external/)
│   ├── guides/
│   │   ├── coldstart-analysis.md            (análise do guia cold start)
│   │   ├── turbo-script-analysis.md         (análise do sandbox_turbo.sh)
│   │   └── turbo-guide-analysis.md          (análise do guia turbo)
│   ├── methods/
│   │   └── repo-documentation-method.md     (análise do guia de doc de repos)
│   ├── skills/
│   │   ├── catalog.md                       (catálogo de 21+70 skills e plugins)
│   │   └── finance-skill-analysis.md        (Yahoo Finance público vs LLM vs RapidAPI)
│   └── projects/
│       └── hybrid-api.md                    (verificação do hybrid-api)
├── scripts/
│   ├── quick_check.sh                       (smoke test 30s)
│   ├── sandbox_inventory.sh                (inventário completo)
│   ├── list_skills.sh                       (skills e plugins)
│   ├── validate_persistence.sh             (simula reset)
│   ├── restore_venv.sh                      (restaura venv Python)
│   ├── test_zai_sdk.py                      (testa SDK z-ai)
│   └── test_hybrid_api.sh                   (testa hybrid-api: 16 endpoints)
├── validation/
│   └── claims_verified.json                 (50+ claims + 5 docs externos + skills catalogados)
└── projects/
    ├── hybrid-api/                          (projeto Bun+Python verificado, 3 bugs corrigidos)
    └── php-runner-v1.0/                     (skill PHP: PHP 8.5.12 + Composer 2.11.1 + PHPUnit 13 + PHPStan 2.3)
```

---

*Para revalidar tudo em sessão futura:* rode `bash z-ai-sandbox/scripts/sandbox_inventory.sh`.

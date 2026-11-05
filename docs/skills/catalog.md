# Skills e Plugins do Sandbox Z.AI

> Investigação completa das skills e plugins disponíveis no sandbox, em 04/11/2026.

## Resumo executivo

| Item | Quantidade | Local |
|---|---|---|
| Skills **instaladas** | **21** | `/home/z/my-project/skills/` |
| Skills **oficiais disponíveis** (zips) | **70** | `/home/official_skills/*.zip` |
| Skills **não instaladas** (mas disponíveis) | **50** | — |
| Stages (presets de skills) | **13** | `/home/official_skills/stages.yaml` |
| Skills **agent-browser** (subskills) | **9** | embarcadas no binário |
| CLI plugins do ecossistema | **9** binários | `/usr/local/bin/` |
| Skills do usuário (modificadas) | **0** | `/home/user_skills/` (limpo) |

---

## 1. Skills instaladas (21)

Lista completa das skills extraídas em `/home/z/my-project/skills/`. **Re-extraídas a cada boot** — não modifique aqui.

### IA / Modelos (4 skills — usam `z-ai-web-dev-sdk`)

| Skill | Tamanho | Descrição |
|---|---|---|
| `LLM` | 40 KB | Chat completion via LLM (glm-4-plus). Para conversas, geração de texto. |
| `VLM` | 32 KB | Visão: análise de imagens com IA (glm-5v-turbo). |
| `TTS` | 32 KB | Texto → fala (voz `tongtong`, só wav/pcm). |
| `ASR` | 32 KB | Fala → texto (reconhecimento). |

### Imagem e vídeo (5 skills)

| Skill | Tamanho | Descrição |
|---|---|---|
| `image-generation` | 32 KB | Geração de imagens IA (1024x1024, ~40s). |
| `image-edit` | 44 KB | Edição de imagens IA. |
| `image-search` | 12 KB | Busca de imagens (retorna URLs OSS embutíveis). |
| `video-understand` | 44 KB | Análise de vídeo (motion, frames, scenes). |
| `agent-browser` | 16 KB | Browser headless Rust+Node para screenshot, automação. |

### Documentos (4 skills)

| Skill | Tamanho | Descrição |
|---|---|---|
| `docx` | 584 KB | Criação/edição de .docx (Word) com python-docx. |
| `pptx` | 472 KB | Criação/edição de .pptx (PowerPoint) com python-pptx. |
| `xlsx` | 276 KB | Planilhas Excel com openpyxl, charts, pivot tables. |
| `pdf` | 1.2 MB | Toolkit PDF: Report (ReportLab), Creative (Playwright), Academic (LaTeX), Process. |

### Charts e visualização (1 skill)

| Skill | Tamanho | Descrição |
|---|---|---|
| `charts` | 228 KB | Charts/diagrams: matplotlib, seaborn, ECharts, D3.js, Mermaid. |

### Dev / Code (5 skills)

| Skill | Tamanho | Descrição |
|---|---|---|
| `fullstack-dev` | 16 KB | Next.js 16 + TypeScript + Tailwind 4 + shadcn/ui + Prisma. |
| `php-runner` | 72 KB | Instala PHP 8.5 + Composer + PHPUnit em ~8s (sem root). |
| `deobfuscate-javascript` | 18 MB | Deobfuscação de JS minificado/obfuscado (humanify). |
| `reverse-engineer-js` | 16 KB | Engenharia reversa de bundles JS (humanify CLI). |
| `skill-creator` | 272 KB | Cria/modifica/avalia skills ClawHub. |

### Meta / Sistema (2 skills)

| Skill | Tamanho | Descrição |
|---|---|---|
| `skill-finder-cn` | 24 KB | Descobre e instala skills ClawHub (busca por nome). |
| `task-review` | 8 KB | Salva tarefas concluídas como skills reutilizáveis. |

---

## 2. Skills oficiais disponíveis (70)

Local: `/home/official_skills/*.zip` — disponíveis para instalação sob demanda. O `start.sh` extrai apenas as listadas no `stages.yaml` (preset do chat atual).

### Categorias

#### IA / Modelos (8)
- `ASR`, `LLM`, `TTS`, `VLM`, `image-generation`, `image-edit`, `image-understand`, `video-generation`

#### Busca / Web (6)
- `agent-browser`, `multi-search-engine`, `image-search`, `ai-news-collectors`, `qingyan-research`, `skill-finder-cn`

#### Documentos (5)
- `docx`, `pdf`, `pptx`, `xlsx`, `quiz-html`

#### Charts / Visualização (3)
- `charts`, `design`, `visual-design-foundations`

#### Dev / Code (8)
- `coding-agent`, `fullstack-dev`, `frontend-design`, `web-shader-extractor`, `version-management`, `writing-plans`, `skill-creator`, `skill-vetter`

#### Pesquisa / Acadêmica (8)
- `aminer-academic-search`, `aminer-daily-paper`, `aminer-deep-search`, `aminer-free-academic`, `aminer-open-academic`, `research-explorer`, `experiment-suite`, `literature-survey`

#### Finanças / Mercado (4)
- `finance`, `stock-analysis-skill`, `market-research-reports`, `contentanalysis`

#### Carreira (5)
- `resume-builder`, `jd-resume-tailor`, `interview-prep`, `interview-designer`, `job-intent-tracker`

#### Conteúdo / Marketing (7)
- `blog-writer`, `content-strategy`, `seo-content-writer`, `marketing-mode`, `storyboard-manager`, `podcast-generate`, `task-review`

#### Gaokao (China) (5)
- `gaokao-collect-student-info`, `gaokao-fetch-volunteers`, `gaokao-generate-report`, `gaokao-recommend-majors`, `gaokao-recommend-schools`

#### Estudo (4)
- `cheat-sheet`, `quiz-mastery`, `study-buddy`, `task-review`

#### Lifestyle / Pessoal (5)
- `gift-evaluator`, `get-fortune-analysis`, `anti-pua`, `dream-interpreter`, `mindfulness-meditation`

#### Misc (2)
- `auto-target-tracker`, `ui-ux-pro-max`

### Lista completa das 50 skills NÃO instaladas (instaláveis sob demanda)

```
ai-news-collectors, aminer-academic-search, aminer-daily-paper,
aminer-deep-search, aminer-free-academic, aminer-open-academic,
anti-pua, auto-target-tracker, blog-writer, cheat-sheet,
coding-agent, content-strategy, contentanalysis, design,
dream-interpreter, experiment-suite, finance, frontend-design,
gaokao-collect-student-info, gaokao-fetch-volunteers,
gaokao-generate-report, gaokao-recommend-majors,
gaokao-recommend-schools, get-fortune-analysis, gift-evaluator,
image-understand, interview-designer, interview-prep,
jd-resume-tailor, job-intent-tracker, literature-survey,
market-research-reports, marketing-mode, mindfulness-meditation,
multi-search-engine, podcast-generate, qingyan-research,
quiz-html, quiz-mastery, research-explorer, resume-builder,
seo-content-writer, skill-vetter, stock-analysis-skill,
storyboard-manager, study-buddy, ui-ux-pro-max,
version-management, video-generation, visual-design-foundations,
web-shader-extractor, writing-plans
```

---

## 3. Stages (presets de skills) — 13

Local: `/home/official_skills/stages.yaml`. Define quais skills são extraídas para cada tipo de chat. **O stage atual do sandbox é `default`** (21 skills).

| Stage | Skills | Foco |
|---|---|---|
| `default` | 21 | Geral: ASR, LLM, VLM, TTS, docx, charts, pdf, pptx, xlsx, agent-browser, skill-creator, image-gen, image-edit, image-search, fullstack-dev, skill-finder-cn, task-review, video-understand, web-reader, web-search |
| `qingyan_writing` | 9 | Escrita criativa (lightweight) |
| `pipi` | 1 | Apenas video-generation |
| `life_coach` | 15 | Coach de vida, conteúdo, mindfulness |
| `professional_writer` | 9 | Marketing, SEO, design, contentanalysis |
| `info_scout` | 9 | Pesquisa, mercado, notícias, academia |
| `cyber_friend` | 17 | Amigo cibernético (escrita + image + anti-pua + meditation) |
| `full_coder` | 6 | Dev full-cycle: writing-plans, coding-agent, fullstack-dev |
| `study_buddy` | 5 | Estudo: cheat-sheet, quiz-mastery, study-buddy |
| `business_professional` | 4 | Carreira: interview-prep, jd-resume-tailor, job-intent-tracker, resume-builder |
| `design` | 2 | design, version-management |
| `EducationTeam` | 10 | Gaokao + utilidades |
| `DefaultTeam` | 9 | VLM + web + docs + charts |
| `FinanceTeam` | 10 | DefaultTeam + finance |
| `research_senior` | 6 | Pesquisa acadêmica avançada |

---

## 4. Skills do `agent-browser` (9 subskills)

Embarcadas no binário `/usr/local/bin/agent-browser` (Rust + Node). Listadas com `agent-browser skills list`:

| Skill | Uso |
|---|---|
| `core` | Guia central (leia primeiro) |
| `agentcore` | Rodar em AWS Bedrock AgentCore (cloud browsers) |
| `derive-client` | Reverse-engineering de API por gravação |
| `dogfood` | Teste exploratório de apps |
| `electron` | Automação de apps Electron (VS Code, Slack, Discord, Figma) |
| `protected-vercel-deployments` | Acessar deployments Vercel protegidos |
| `slack` | Automação de Slack workspaces |
| `vercel-sandbox` | Rodar em Vercel Sandbox microVMs |
| `webmcp-gen` | Construir WebMCP tools experimentais |

Acesso: `agent-browser skills get <name>` (carrega skill específica).

---

## 5. Plugins / CLIs do ecossistema Z.AI (9 binários)

Em `/usr/local/bin/`:

| Binário | Versão | O que é |
|---|---|---|
| `z-ai` | 0.0.18 | CLI principal do SDK z-ai-web-dev-sdk (10 subcomandos) |
| `z-ai-generate` | 0.0.18 | Alias backward-compat para `z-ai image` |
| `agent-browser` | 0.41.1 | Browser automation CLI (Rust + Node fallback) |
| `bun` | 1.3.14 | Runtime JS da plataforma |
| `bunx` | — | Executor de binários npm via bun |
| `uv` | 0.13.7 | Gerenciador de pacotes/venvs Python |
| `uvx` | — | Executor de pacotes Python via uv (como npx) |
| `tectonic` | 0.15.0 | Motor LaTeX (PDF via pandoc) |
| `docker-entrypoint.sh` | — | Helper do container |

---

## 6. SDK `z-ai-web-dev-sdk` (API interna)

Local: `/home/z/.bun/install/global/node_modules/z-ai-web-dev-sdk/`

### Endpoints (10)

| Endpoint | Função |
|---|---|
| `chat.completions.create(body)` | Chat LLM (glm-4-plus) |
| `chat.completions.createVision(body)` | Visão (glm-5v-turbo) |
| `audio.tts.create(body)` | Texto → fala |
| `audio.asr.create(body)` | Fala → texto |
| `images.generations.create(body)` | Gerar imagem |
| `images.generations.edit(body)` | Editar imagem |
| `images.search.create(body)` | Buscar imagem (URLs OSS) |
| `video.generations.create(body)` | Gerar vídeo |
| `async.result.query(taskId)` | Resultado assíncrono |
| `functions.invoke(name, args)` | Funções (web_search, page_reader) |

### Subcomandos CLI (10)

```bash
z-ai chat --prompt "..."
z-ai vision --image ...
z-ai tts --text "..." --format wav
z-ai asr --audio ...
z-ai image --prompt "..."
z-ai image-edit ...
z-ai image-search ...
z-ai video ...
z-ai async-result --task-id ...
z-ai function -n <name> -a '<args_json>'
```

### Auth

- **Zero config** — lê `/etc/.z-ai-config` (444, root) automaticamente
- Variáveis `Z.AI_API_KEY` e `Z.AI_BASE_URL` **NÃO existem**
- Default import: `import ZAI from 'z-ai-web-dev-sdk'` (não `{ ZAI }`)

---

## 7. Skills do usuário (`/home/user_skills/`)

Atualmente vazio (limpo pelo usuário). Para criar skill customizada persistida entre resets, copie o zip para `/home/user_skills/<skill-name>.zip` (mount PolarFS, persiste).

---

## 8. MCP (Model Context Protocol)

### No venv Python (430 pacotes)

- `mcp` 1.27.0 — SDK oficial (client + server + CLI `mcp dev/run/install`)
- `fastmcp` 2.14.3 — framework standalone, binário `fastmcp`

### Uso típico

```bash
# Servidor MCP próprio (FastMCP):
python3 /home/z/my-project/scripts/mcp_demo_server.py

# Cliente MCP oficial:
npx -y @modelcontextprotocol/server-everything
uvx mcp-server-time
```

### MCP remoto (sem instalar nada)

```python
from mcp.client.streamablehttp import streamablehttp_client
async with streamablehttp_client("https://mcp.jina.ai/v1") as (r, s):
    # initialize → list_tools → call_tool
    ...
```

---

## 9. Como adicionar uma skill não-instalada

Se você (IA) precisa de uma skill que está em `/home/official_skills/` mas não foi extraída para o stage atual:

```bash
# 1. Extraia manualmente o zip:
unzip -qq -o /home/official_skills/<skill_name>.zip -d /home/z/my-project/skills/

# 2. Ajuste permissões:
chown -R z:z /home/z/my-project/skills/<skill_name>
chmod -R 755 /home/z/my-project/skills/<skill_name>

# 3. Verifique:
ls /home/z/my-project/skills/<skill_name>/
```

**⚠️ Atenção:** o `start.sh` re-extrai apenas as skills do `stages.yaml` a cada boot. Skills extraídas manualmente **NÃO persistem** entre resets (são sobrescritas). Para persistência, copie para `tools/` em vez de `skills/`.

## 10. Como descobrir skills do ClawHub (externas)

Use a skill `skill-finder-cn` instalada:

```
"encontre uma skill para análise de sentimento"
"procure skills para criar mindmaps"
```

A skill consulta o ClawHub e retorna skills instaláveis.

Ou use o `clawhub` CLI diretamente:

```bash
clawhub search <query>          # buscar skills no registry público
clawhub login                   # autenticar com conta ClawHub
clawhub install <skill-name>    # instalar skill
```

## 11. Verificação rápida (comando único)

```bash
# Listar skills instaladas:
ls /home/z/my-project/skills/ | wc -l

# Listar skills oficiais disponíveis:
ls /home/official_skills/*.zip | wc -l

# Ver stage atual:
head -30 /home/official_skills/stages.yaml

# Listar skills agent-browser:
agent-browser skills list

# Ver funções do SDK z-ai:
z-ai --help
```

---

## 12. Mapa final de skills/plugins

```
Sandbox Z.AI
├── skills/                              (gerenciadas por stages.yaml)
│   ├── /home/z/my-project/skills/        (21 skills instaladas, re-extraídas/boot)
│   ├── /home/official_skills/           (70 zips oficiais, somente leitura)
│   ├── /home/user_skills/               (0 zips customizados pelo usuário — limpo)
│   └── stages.yaml                       (13 stages com presets)
│
├── CLI plugins                          (/usr/local/bin/)
│   ├── z-ai, z-ai-generate              (SDK IA)
│   ├── agent-browser                    (browser automation)
│   ├── bun, bunx                        (runtime JS)
│   ├── uv, uvx                          (Python package manager)
│   └── tectonic                         (LaTeX)
│
├── SDK z-ai-web-dev-sdk v0.0.18          (~/.bun/install/global/)
│   └── 10 endpoints (chat, vision, tts, asr, image, video, function...)
│
└── MCP                                  (~/.venv/)
    ├── mcp 1.27.0                       (Python SDK)
    └── fastmcp 2.14.3                   (framework standalone)
```

---

*Investigação realizada em 04/11/2026 por listagem direta dos diretórios, extração de descrições de cada `SKILL.md` e leitura do `stages.yaml`.*

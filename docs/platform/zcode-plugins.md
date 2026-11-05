# ZCode Server v3.16.2 — Os 14 Plugins

> Investigação detalhada de cada plugin do ZCode em 04/11/2026.
> Fonte: `/opt/zcode/rt/manifest.json` + `package.json` de cada plugin + estrutura de `skills/` e `dist/`.

## Resumo

O ZCode Server (source `zcode` no gateway) vem com **14 plugins oficiais**, totalizando **24 skills** internas. Cada plugin pode incluir:
- **Skills** (instruções para o agente usar ferramentas específicas)
- **MCP server** (servidor JSON-RPC que implementa as tools da skill)
- **Comandos** (ações acionáveis via CLI)
- **Hooks** (interceptam eventos do agente)
- **Output styles** (estilos de output customizados)
- **Dist** (código compilado)

## Tabela completa dos 14 plugins

| # | Plugin | Versão | Skills | MCP server | Descrição |
|---|---|---|---|---|---|
| 1 | `android-emulator` | 0.1.0 | 1 | ✅ | Emulador Android |
| 2 | `browser-use` | 0.5.1 | 2 | ✅ | Browser automation (skill oficial + client runtime + node_repl MCP) |
| 3 | `documents` | 0.2.0 | 2 | ✅ | Criação de .docx + Word viewer panel |
| 4 | `image-search` | 0.1.1 | 0 | — | MCP server para busca de imagens (ilustrações, referências) |
| 5 | `ios-simulator` | 0.1.0 | 1 | ✅ | Simulador iOS |
| 6 | `pdf` | 0.2.1 | 2 | ✅ | Criação de PDF + PDF viewer panel |
| 7 | `plugin-creator` | 0.1.1 | 1 | ✅ | Scaffolding para criar novos plugins ZCode |
| 8 | `presentations` | 0.2.0 | 2 | ✅ | Criação de .pptx + PowerPoint viewer panel |
| 9 | `restore-legacy-sessions` | 0.1.0 | 1 | — | Restauração de sessões legadas do ZCode |
| 10 | `skill-creator` | 0.1.0 | 1 | — | Criação de skills (publicada como plugin oficial) |
| 11 | `spreadsheets` | 0.2.0 | 2 | ✅ | Criação de .xlsx + Excel viewer panel |
| 12 | `visualize` | 0.1.0 | 1 | — | ZCode Gen UI (autoracia de interfaces visuais) |
| 13 | `zcode-cua` | 0.6.5 | 1 | ✅ | **Computer Use Agent** — controle de apps desktop nativos |
| 14 | `zcode-guide` | 0.3.0 | 6 | — | Guia de uso + diagnóstico (commands, hooks, mcp, plugins, skills) |

**Total:** 14 plugins, **24 skills**, **9 MCP servers**.

---

## Detalhe de cada plugin

### 1. `android-emulator` v0.1.0

**Estrutura:** README.md, commands/, dist/, hooks/, output-styles/, package.json, scripts/, skills/

**Skill:**
- `android-dev` — desenvolvimento Android no emulador

**Provável uso:** rodar apps Android em emulador para testes/automação (provavelmente usa o emulador Android SDK).

### 2. `browser-use` v0.5.1

**Estrutura:** README.md, dist-types/, docs/, e2e/, package.json, scripts/, skills/, src/

**Descrição (do `package.json`):**
> "作为官方 ZCode 内置插件发布的 Browser Use skill 与 client runtime；node_repl MCP server 由 @zcode/node-repl-host 提供."
> (Skill e client runtime do Browser Use publicado como plugin oficial do ZCode; o MCP server node_repl é fornecido por @zcode/node-repl-host.)

**Skills (2):**
- `control-browser` — controle de browser via automação
- `web-gui-tester` — testes de GUI web

**Provável uso:** automação de browsers (diferente do `agent-browser` CLI — este é mais voltado ao ZCode).

### 3. `documents` v0.2.0

**Estrutura:** agents/, dist/, package.json, skills/

**Descrição:**
> "DOCX document production skills and a Word viewer panel, published as an official ZCode plugin."

**Skills (2):**
- `docx` — criação de documentos Word
- `docx-viewer` — painel para visualizar .docx

**MCP server:** `dist/server.mjs`

### 4. `image-search` v0.1.1

**Estrutura:** README.md, README_CN.md, package.json (sem skills/)

**Descrição:**
> "Official ZCode image search MCP server for finding illustrations and reference images."

**Skills:** 0 (é só MCP server)

**Provável uso:** MCP server dedicado para busca de imagens (encontrar ilustrações e imagens de referência para documentos).

### 5. `ios-simulator` v0.1.0

**Estrutura:** README.md, commands/, dist/, hooks/, output-styles/, package.json, scripts/, skills/

**Skill:**
- `ios-dev` — desenvolvimento iOS no simulador

**Provável uso:** rodar apps iOS no simulador (Xcode iOS Simulator). Simétrico ao `android-emulator`.

### 6. `pdf` v0.2.1

**Estrutura:** agents/, dist/, package.json, skills/

**Descrição:**
> "PDF production skills and a PDF viewer panel, published as an official ZCode plugin."

**Skills (2):**
- `pdf` — criação de PDF
- `pdf-viewer` — painel para visualizar PDF

**MCP server:** `dist/server.mjs`

### 7. `plugin-creator` v0.1.1

**Estrutura:** package.json, skills/, test/

**Descrição:**
> "Built-in ZCode plugin authoring skill and scaffolding helpers."

**Skill:**
- `plugin-creator` — scaffolding para criar novos plugins ZCode

**Provável uso:** helper para desenvolvedores criarem novos plugins ZCode.

### 8. `presentations` v0.2.0

**Estrutura:** agents/, dist/, package.json, skills/

**Descrição:**
> "PPTX presentation production skills and a PowerPoint viewer panel, published as an official ZCode plugin."

**Skills (2):**
- `pptx` — criação de apresentações PowerPoint
- `pptx-viewer` — painel para visualizar .pptx

**MCP server:** `dist/server.mjs`

### 9. `restore-legacy-sessions` v0.1.0

**Estrutura:** README.md, commands/, package.json, skills/

**Skill:**
- `restore-legacy-sessions` — restauração de sessões antigas do ZCode

**Provável uso:** retrocompatibilidade — migrar/recuperar sessões de versões anteriores do ZCode.

### 10. `skill-creator` v0.1.0

**Estrutura:** package.json, skills/

**Descrição:**
> "Built-in skill-creator skills published as an official ZCode plugin."

**Skill:**
- `skill-creator` — criação de skills

**Note:** Similar ao `skill-creator` que temos no ClawHub (pasta `/home/z/my-project/skills/skill-creator/`), mas empacotado como plugin ZCode.

### 11. `spreadsheets` v0.2.0

**Estrutura:** agents/, dist/, package.json, skills/

**Descrição:**
> "XLSX spreadsheet production skills and an Excel viewer panel, published as an official ZCode plugin."

**Skills (2):**
- `xlsx` — criação de planilhas Excel
- `xlsx-viewer` — painel para visualizar .xlsx

**MCP server:** `dist/server.mjs`

### 12. `visualize` v0.1.0

**Estrutura:** package.json, skills/

**Descrição:**
> "ZCode Gen UI authoring skill and examples"

**Skill:**
- `visualize` — autoracia de UI visual (Gen UI)

**Provável uso:** gerar componentes UI a partir de descrições (ex: "crie um card com título e botão" → gera o código).

### 13. `zcode-cua` v0.6.5 (Computer Use Agent) ⭐

**Estrutura:** docs/, package.json, scripts/, skills/, tests/, tsconfig.json

**Descrição:**
> "ZCode CUA SDK and skill package; execution is provided by the shared node_repl host."

**Skill (1):**
- `computer-use` — controle de apps desktop nativos via UI

**SKILL.md (trecho):**
```markdown
---
name: computer-use
description: "Use when a task needs a native desktop app's own UI or the OS. For anything
  inside a web page, use Browser Use. Main agent only."
---

# Computer Use

Read or operate the UI of native apps on the user's computer.

- Prefer a dedicated connector, API, CLI or skill when one can complete the task.
- For browser and web tasks, use Browser Use instead.
- Do not use AppleScript, osascript, JXA, System Events, shell commands, or any
  other UI-automation technology unless the user explicitly asks for that technology.
- Main agent only. Never delegate Computer Use to a subagent.
```

**Provável uso:** similar ao "Computer Use" da Anthropic — controlar mouse/teclado de apps desktop. Requer `node_repl` host compartilhado.

### 14. `zcode-guide` v0.3.0

**Estrutura:** README.md, package.json, skills/

**Descrição:**
> "作为官方 ZCode 内置插件发布的使用与自诊断指南技能集."
> (Conjunto de skills de uso e autodiagnóstico publicadas como plugin oficial do ZCode.)

**Skills (6) — conjunto de diagnóstico:**
- `diagnosing-commands` — diagnosticar problemas com comandos
- `diagnosing-hooks` — diagnosticar hooks
- `diagnosing-mcp` — diagnosticar MCP servers
- `diagnosing-plugins` — diagnosticar plugins
- `diagnosing-skills` — diagnosticar skills
- `zcode-configuration-guide` — guia de configuração

**Provável uso:** toolkit de autodiagnóstico do próprio ZCode — quando algo dá errado, o agente pode usar essas skills para debugar.

---

## Skills totais (24) — lista completa

```
android-emulator:
  - android-dev

browser-use:
  - control-browser
  - web-gui-tester

documents:
  - docx
  - docx-viewer

image-search:
  (sem skills — só MCP server)

ios-simulator:
  - ios-dev

pdf:
  - pdf
  - pdf-viewer

plugin-creator:
  - plugin-creator

presentations:
  - pptx
  - pptx-viewer

restore-legacy-sessions:
  - restore-legacy-sessions

skill-creator:
  - skill-creator

spreadsheets:
  - xlsx
  - xlsx-viewer

visualize:
  - visualize

zcode-cua:
  - computer-use

zcode-guide:
  - diagnosing-commands
  - diagnosing-hooks
  - diagnosing-mcp
  - diagnosing-plugins
  - diagnosing-skills
  - zcode-configuration-guide
```

**Total: 24 skills em 14 plugins.**

---

## Comparação: ZCode plugins vs. ClawHub skills (do nosso sandbox)

| Categoria | ZCode Plugin | ClawHub Skill (no nosso sandbox) | Diferença |
|---|---|---|---|
| Documentos Word | `documents` plugin (docx + viewer) | `docx` skill | ZCode tem viewer panel |
| Apresentações | `presentations` (pptx + viewer) | `pptx` skill | ZCode tem viewer panel |
| Planilhas | `spreadsheets` (xlsx + viewer) | `xlsx` skill | ZCode tem viewer panel |
| PDF | `pdf` (pdf + viewer) | `pdf` skill | ZCode tem viewer panel |
| Browser | `browser-use` (control + tester) | `agent-browser` skill | Diferentes implementações |
| Criação de skills | `skill-creator` + `plugin-creator` | `skill-creator` skill | ZCode tem 2 (skill e plugin) |
| Imagens | `image-search` MCP | `image-search` skill | ZCode é MCP server |
| Computer Use | `zcode-cua` (computer-use) | (não temos) | **NOVO no ZCode** |
| Diagnóstico | `zcode-guide` (6 skills) | (não temos) | **NOVO no ZCode** |
| Mobile | `android-emulator` + `ios-simulator` | (não temos) | **NOVO no ZCode** |
| Gen UI | `visualize` | (não temos) | **NOVO no ZCode** |
| Legacy | `restore-legacy-sessions` | (não temos) | **NOVO no ZCode** |

**Insight:** O ZCode é focado em **desenvolvimento desktop/IDE** (com viewers, emuladores, computer use, diagnóstico). O ClawHub (que temos) é focado em **automação web-dev e I/O** (chat, visão, busca web, geração de imagens).

---

## Arquitetura ZCode (resumo)

```
ZCode Server v3.16.2
├── runtime/
│   ├── node (Node 22.16.0 embarcado)
│   ├── server-cli.js (entrypoint CLI)
│   ├── server-core.js (entrypoint core)
│   ├── zcode.cjs (entrypoint agent)
│   ├── node_modules/
│   ├── tools/ (bfs, ripgrep, ugrep — busca de arquivos)
│   └── packages/ (14 plugins)
│       ├── android-emulator-plugin/    (mobile dev)
│       ├── browser-use-plugin/         (browser automação)
│       ├── documents-plugin/          (Word docx)
│       ├── image-search-plugin/       (busca imagens)
│       ├── ios-simulator-plugin/      (iOS dev)
│       ├── pdf-plugin/                (PDF)
│       ├── plugin-creator-plugin/    (scaffolding)
│       ├── presentations-plugin/     (PowerPoint)
│       ├── restore-legacy-sessions-plugin/  (migração)
│       ├── skill-creator-plugin/     (criar skills)
│       ├── spreadsheets-plugin/      (Excel)
│       ├── visualize-plugin/         (Gen UI)
│       ├── zcode-cua-plugin/         (Computer Use)
│       └── zcode-guide-plugin/       (diagnóstico)
└── bundled-skills/
    └── skills/
        └── dynamic-workflows/        (1 skill bundled)
```

---

## Onde o ZCode se encaixa no ecossistema Z.AI

```
┌────────────────────────────────────────────────────┐
│  Sandbox Z.AI (este container)                     │
│                                                    │
│  ┌──────────────────┐  ┌──────────────────┐         │
│  │  Agente "Z"      │  │  Agente "zcode"  │         │
│  │  (chat web-dev)  │  │  (ZCode Server)  │         │
│  │                  │  │  v3.16.2          │         │
│  │  Rate limitado   │  │  14 plugins      │         │
│  │  Tools: SDK z-ai │  │  24 skills       │         │
│  │  + agent-browser │  │  9 MCP servers   │         │
│  │  + 21 ClawHub    │  │  + Computer Use  │         │
│  │    skills        │  │  + 6 mobile (iOS │         │
│  └────────┬─────────┘  │    + Android)    │         │
│           │            └────────┬─────────┘         │
│           ↓                     ↓                   │
│  Gateway internal-api.z.ai/v1                      │
│  (source: Z, source: zcode, source: zai-agent)     │
└────────────────────────────────────────────────────┘
```

**Note:** o agente `zcode` (ZCode Server) está instalado no sandbox mas **não está rodando neste momento** (a não ser que o usuário tenha rodado `/opt/zcode/rt/bin/zcode` manualmente). Para iniciá-lo:

```bash
/opt/zcode/rt/bin/zcode
# (mas precisa de credenciais próprias — Z.AI Coding Plan)
```

---

*Investigação realizada em 04/11/2026 por leitura direta de `/opt/zcode/rt/manifest.json`, `package.json` de cada plugin, e estrutura de `skills/` e `dist/` em cada um dos 14 plugins.*

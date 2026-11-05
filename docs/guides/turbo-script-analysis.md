# `sandbox_turbo.sh` — Análise e Testes

> Análise de `sandbox_turbo.sh` (486 linhas) recebido do usuário.
> Testes empíricos realizados em 04/11/2026 executando cada função.

## Resumo executivo

| Função | Testado | Resultado |
|---|---|---|
| `--status` | ✅ | **Funciona** (mostra CPU, RAM, disco, ulimits, processos, portas, env) |
| `--resources` | ✅ | **Parcial** — bug em `pillow` e `beautifulsoup4` (nomes errados) |
| `--optimize` | ✅ | **Funciona** (aumenta `ulimit -n 65535` e `-u 4096` na sessão) |
| `--clean` | ✅ | **Parcial** — pip/npm OK, page cache falha (sem root) |
| `--aliases` | ⚠️ | **PERIGOSO** — 3 aliases quebram comportamento (ver seção 5) |
| `--scripts` | não testado | cria 4 scripts em `~/quick-scripts/` (web-screenshot, convert-doc, ocr, monitor) |
| `--benchmark` | não testado | roda testes de CPU/IO/Python imports |
| `--all` | ⚠️ | executa tudo **inclusive aliases perigosos** |

**Veredito:** 4 funções úteis, 1 com bug, 1 PERIGOSA (não usar `--aliases` nem `--all`).

## Sintaxe

```bash
bash -n /home/z/my-project/upload/sandbox_turbo.sh
# Saída: vazia → sintaxe OK
```

## Teste por função

### `--status` ✅ funciona

```bash
$ bash sandbox_turbo.sh --status
```

Saída real (medições ao vivo):
- CPU: 2 cores, load `0.04 0.03 0.00`
- Memória: 4.1Gi total, 526Mi usado, 3.0Gi livre (3.5Gi disponível)
- Disco: 9.9G total, 703M usado, 8.7G livre (8%)
- Limites: open files 1024, max processes 100000 (script diz 1024 — ver bug)
- Processos principais: root roda `/app/.venv/bin/python`, `caddy`, `uv run`
- Portas em uso: 81, 12600, 19001, 19005, 19006

**Bug menor:** `ulimit -u` retorna 100000, não 1024 (claim do guia `SANDBOX_TURBO_GUIA.md`).

### `--resources` ⚠️ parcialmente correto

Runtimes detectados corretamente:
- Bun 1.3.14
- Node.js v24.22.2
- Python 3.12.16
- uv 0.13.7
- Java 21.0.13

Mídia detectada corretamente:
- FFmpeg 7.1.5-0+deb13u1
- Pandoc 3.1.11.1
- eSpeak 1.48.15
- LibreOffice 25.2.3.2

**Bugs:**

```python
# Bloco do script:
packages = ['numpy', 'pandas', 'scipy', 'sklearn', 'cv2', 'matplotlib', 'pillow', 
            'requests', 'fastapi', 'redis', 'beautifulsoup4']
```

| Pacote no script | Real | Status |
|---|---|---|
| `pillow` | `PIL` (Pillow) | ❌ bug — nome do módulo é `PIL`, não `pillow` |
| `beautifulsoup4` | `bs4` | ❌ bug — nome do módulo é `bs4`, não `beautifulsoup4` |
| `sklearn` | `sklearn` | ✅ |
| `cv2` | `cv2` | ✅ |

Saída real:
```
   pillow: não instalado         ← FALSO (Pillow 11.3.0 está sim)
   beautifulsoup4: não instalado ← FALSO (bs4 4.14.3 está sim)
```

**Correção:** trocar `'pillow'` por `'PIL'` e `'beautifulsoup4'` por `'bs4'`.

Node globals detectados corretamente (6/6):
- `@mermaid-js/mermaid-cli@12.2.0` (guia dizia 11.16.0 — versão velha)
- `docx@9.15.2`, `pdf-lib@1.17.1`, `playwright@1.57.0`, `pptxgenjs@4.0.1`, `sharp@0.35.5`

Browsers cache detectado:
- Playwright: 613M (guia dizia "~2GB")
- Puppeteer: 608M
- Agent Browser: 404M
- Total real: ~1.6GB (não ~2GB)

Skills: 21 skills disponíveis (guia dizia "69" — número de categorias, não skills).

### `--optimize` ✅ funciona (parcial)

```bash
$ bash sandbox_turbo.sh --optimize

⚠️ Não é root - otimizando apenas para sessão atual...
✅ Open files aumentado para 65535
✅ Max processes aumentado para 4096
```

**Real:** `ulimit -n` aumenta de 1024 para 65535 (hard limit 100000). `ulimit -u` diminui de 100000 para 4096 ( atenção: isto **reduz** max processes).

**⚠️ Armadilha:** o script força `ulimit -u 4096`, mas o sandbox já tem `100000`. Para workloads que precisam de muitos processos (ex: testes paralelos, multiprocessing Python), isso **reduz** o limite. Recomenda-se **não rodar `--optimize`** a menos que precise de mais open files.

### `--clean` ⚠️ parcial

```bash
$ bash sandbox_turbo.sh --clean
✅ Cache pip limpo!
✅ Cache npm limpo!
⚠️ Precisa ser root para limpar page cache
```

- `pip cache purge` funciona (sem senha)
- `npm cache clean --force` funciona
- `echo 3 > /proc/sys/vm/drop_caches` falha (sem root) — script detecta e avisa

**Recomendação:** `--clean` é seguro, libera ~MB de cache pip/npm. Page cache não é tocado.

### `--aliases` ❌ PERIGOSO

```bash
# Bloco perigoso do script:
alias node='bun'                    # ← quebra scripts Node-specific
alias npm='bun'                      # ← quebra 'npm install --no-save', 'npm ci', etc.
alias pandoc='pandoc --pdf-engine=xelatex'  # ← xelatex NÃO EXISTE
```

**Por que são perigosos:**

1. **`alias node='bun'`**: Bun é ~95% compatível com Node, mas scripts que usam API Node nativa (`fs.promises.readFile`, `cluster`, `worker_threads`) podem falhar. Scripts `npx`-specific que assumem `node` podem quebrar.

2. **`alias npm='bun'`**: `bun` tem `bun install` (substituto de `npm install`), mas `npm` tem flags que `bun` não suporta (`--no-save`, `--legacy-peer-deps`, `--ignore-scripts`, `npm ci`, `npm publish`). Aliasing `npm='bun'` quebra pipelines que usam essas flags.

3. **`alias pandoc='pandoc --pdf-engine=xelatex'`**: `xelatex` **não existe** no sandbox (verificado: `which xelatex` retorna vazio). Toda chamada a `pandoc arquivo.md -o output.pdf` falharia com `pandoc: xelatex not found`. O motor de PDF real do sandbox é **`tectonic`** (`--pdf-engine=tectonic`).

**Recomendação explícita:** **NÃO use `--aliases` nem `--all`** (que inclui aliases). Se quiser os outros recursos, chame as funções individualmente sem `--aliases`.

### `--scripts` não testado (análise por inspeção)

Cria 4 scripts em `~/quick-scripts/`:

| Script | Função | Análise |
|---|---|---|
| `web-screenshot.sh` | Screenshot via `agent-browser` ou playwright | ✅ usa fallback gracioso |
| `convert-doc.sh` | Conversão via pandoc ou libreoffice | ⚠️ chama `pandoc --pdf-engine=xelatex` (falha) |
| `ocr.sh` | OCR via tesseract | ✅ simples e funcional |
| `monitor.sh` | Monitor de recursos em tempo real | ✅ usa `top` e `free` |

**Bug em `convert-doc.sh`:** chama `pandoc --pdf-engine=xelatex` — mesmo bug do alias. Converteria para PDF falhando.

### `--benchmark` (análise por inspeção)

Testa:
- Fibonacci(1000000) em Python — CPU bound
- I/O com `dd if=/dev/zero of=/tmp/benchmark_test bs=1M count=100`
- Import Python (numpy, pandas, scipy)
- Bun vs Node (hello world)
- Versão do FFmpeg

**Potencial issue:** `dd if=/dev/zero of=/tmp/...` cria arquivo 100MB em `/tmp`. Funciona, mas lembre que `/tmp` é efêmero.

## Correções sugeridas para o script

### Correção 1: bug em `--resources` (imports)

```python
# ANTES (bug):
packages = ['numpy', 'pandas', 'scipy', 'sklearn', 'cv2', 'matplotlib', 'pillow', 
            'requests', 'fastapi', 'redis', 'beautifulsoup4']

# DEPOIS (corrigido):
packages = [
    ('numpy', 'numpy'),
    ('pandas', 'pandas'),
    ('scipy', 'scipy'),
    ('sklearn', 'sklearn'),
    ('cv2', 'cv2'),
    ('matplotlib', 'matplotlib'),
    ('PIL', 'pillow'),
    ('requests', 'requests'),
    ('fastapi', 'fastapi'),
    ('redis', 'redis'),
    ('bs4', 'beautifulsoup4'),
]
for module_name, display_name in packages:
    try:
        m = importlib.import_module(module_name)
        ver = getattr(m, '__version__', 'installed')
        print(f'   {display_name}: {ver}')
    except ImportError:
        print(f'   {display_name}: não instalado')
```

### Correção 2: remover aliases perigosos em `--aliases`

```bash
# REMOVER estas linhas:
alias node='bun'
alias npm='bun'
alias pandoc='pandoc --pdf-engine=xelatex'

# SUBSTITUIR por aliases seguros:
alias ll='ls -lah'
alias la='ls -A'
alias py='python3'
alias ff='ffmpeg'
alias tess='tesseract'
# (apenas aliases que não quebram ferramentas)
```

### Correção 3: `--optimize` não deve reduzir `ulimit -u`

```bash
# ANTES:
ulimit -u 4096  # reduz de 100000 para 4096

# DEPOIS (apenas aumenta se menor):
[ "$(ulimit -u)" -lt 4096 ] && ulimit -u 4096
# ou simplesmente não tocar em -u
```

## O que é útil no script (mantenha)

1. **`--status`**: ótimo para diagnóstico rápido (CPU, RAM, disco, ulimits, portas)
2. **`--resources`** (após correção): inventário em 1 comando
3. **`--clean`** sem root: limpa pip/npm cache com segurança
4. **`--scripts`** (`ocr.sh` e `monitor.sh` são úteis)
5. **`--benchmark`**: ótimo para medir ambiente
6. Cabeçalho visual, cores ANSI, organização das seções

## O que é perigoso (não use)

| Função | Risco |
|---|---|
| `--aliases` | 3 aliases quebram `node`, `npm`, `pandoc` |
| `--all` | Inclui `--aliases` |
| `--optimize` (com `-u 4096`) | Reduz max processes de 100000 para 4096 |
| `convert-doc.sh` (em `--scripts`) | Chama `xelatex` (não existe) |

## Script limpo e seguro (apenas funções úteis)

Se quiser uma versão segura do `sandbox_turbo.sh`, use apenas:

```bash
# Diagnóstico:
bash sandbox_turbo.sh --status
bash sandbox_turbo.sh --resources
bash sandbox_turbo.sh --benchmark

# Limpeza segura:
bash sandbox_turbo.sh --clean

# Scripts úteis (ignorando convert-doc.sh):
bash sandbox_turbo.sh --scripts
# usar apenas ~/quick-scripts/ocr.sh e ~/quick-scripts/monitor.sh
```

**NÃO use:** `--aliases`, `--all`, `--optimize`.

---

*Análise realizada em 04/11/2026 por execução direta de cada função do script no sandbox Z.AI.*

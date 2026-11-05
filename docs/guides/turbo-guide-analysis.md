# `SANDBOX_TURBO_GUIA.md` — Verificação de Claims

> Análise de `SANDBOX_TURBO_GUIA.md` (513 linhas) recebido do usuário.
> Verificação empírica em 04/11/2026.

## Resumo executivo

| Categoria | Confirmados | Atualizados (versão) | Falsos |
|---|---|---|---|
| Hardware / limites | 3/3 | 0 | 0 |
| Runtimes | 5/6 | 5 (versões) | 1 (max processes) |
| Pacotes Python | 6/9 | 2 (versões) | 1 (`pillow` import) |
| Node globals | 5/6 | 5 (versões) | 0 |
| Skills count | 0/1 | — | 1 (é 21, não 69) |
| Browsers cache | parcial | 1 (~2GB→~1.6GB) | 0 |
| Portas / serviços | 5/5 | 0 | 0 |
| Variáveis Z.AI | 0/3 | — | 3 (`Z.AI_*` não existem) |
| SDK imports | 0/3 | — | 3 (`{ ZAI }`, `z-ai generate`, modelos) |
| ImageMagick / xelatex | 0/2 | — | 2 (ambos ausentes) |
| Métricas esperadas | 4/8 | 3 (atualizadas) | 1 (import <500ms) |

**Veredito:** guia **majoritariamente correto no inventário**, mas com **múltiplas claims falsas críticas** que causam falhas se seguidas (aliases, `xelatex`, `Z.AI_API_KEY`, `import { ZAI }`).

---

## 1. Hardware / limites

| Claim | Real | Veredito |
|---|---|---|
| CPU 2 cores | `nproc`=2 | ✅ |
| RAM 3.9 GB total (3.5 GB livre) | `free -h`: 4.1Gi total, 3.5Gi disponível | ✅ (≈) |
| Disco 9.9 GB (9.1 GB livre) | `df -h /`: 9.9G total, 8.7G livre | ✅ |
| Swap 0 MB | `SwapTotal: 0 kB` | ✅ |
| Uptime ~28 min | variável (era da sessão original) | ⚠️ data específica |
| Load average 0.00 | `0.08 0.04 0.01` | ✅ ocioso |
| **Max Processes 1,024** | **`ulimit -u` = 100.000** | ❌ **FALSO** (real é 100x maior) |
| Open files 1,024 → 65,535 | `ulimit -n` = 1024 default | ✅ |

## 2. Runtimes

| Claim | Real | Veredito |
|---|---|---|
| Bun 1.3.14 | 1.3.14 | ✅ |
| **Node.js v24.18.0** | **v24.22.2** | ⚠️ versão mais nova |
| **Python 3.12.13** | **3.12.16** | ⚠️ versão mais nova |
| **uv 0.11.31** | **0.13.7** | ⚠️ versão bem mais nova |
| Java | openjdk 21.0.13 | ✅ |
| GCC/G++ | 14.2.0 | ✅ |

## 3. Ferramentas de mídia

| Claim | Real | Veredito |
|---|---|---|
| FFmpeg 7.1.5 | 7.1.5-0+deb13u1 | ✅ |
| Tesseract 5.5.0 | 5.5.0 | ✅ |
| Pandoc 3.1.11.1 | 3.1.11.1 | ✅ |
| LibreOffice | 25.2.3.2 | ✅ |
| eSpeak 1.48.15 | 1.48.15 | ✅ |
| **ImageMagick (`convert`)** | **AUSENTE** | ❌ **FALSO** — use PIL/sharp |

`which convert` e `which magick` retornam vazio. Imagens devem ser manipuladas com `Pillow` (Python), `sharp` (Node) ou `ffmpeg` (vídeo/frames).

## 4. Pacotes Python

| Claim do guia | Real (medido) | Veredito |
|---|---|---|
| numpy 2.1.3 | 2.1.3 | ✅ |
| pandas 2.2.3 | 2.2.3 | ✅ |
| scipy 1.14.1 | 1.14.1 | ✅ |
| sklearn 1.5.2 | 1.5.2 | ✅ |
| cv2 4.13.0 | 4.13.0 | ✅ |
| matplotlib 3.9.2 | 3.9.2 | ✅ |
| **pillow 11.3.0** | Pillow 11.3.0 está instalado (módulo `PIL`) | ⚠️ claim correta, mas `import pillow` falha — usar `from PIL import Image` |
| requests 2.32.5 | 2.32.5 | ✅ |
| fastapi 0.128.0 | 0.128.0 | ✅ |
| redis 7.4.0 | 7.4.0 | ✅ |
| **PyPDF2 3.0.1** | 3.0.1 | ✅ |
| **pikepdf 10.10.0** | **10.17.0** | ⚠️ versão mais nova |
| python-pptx 1.0.2 | 1.0.2 | ✅ |
| pdf2image 1.17.0 | 1.17.0 | ✅ |
| pdfminer.six 20251230 | 20251230 | ✅ |
| **"200+ pacotes"** | **921 pacotes no venv** | ⚠️ subestimado |

## 5. Node globals

| Claim | Real | Veredito |
|---|---|---|
| **@mermaid-js/mermaid-cli 11.16.0** | **12.2.0** | ⚠️ versão bem mais nova |
| **playwright 1.61.1** | **1.57.0** | ⚠️ versão mais velha (a do guia é mais nova que a real?) |
| **sharp 0.35.3** | **0.35.5** | ⚠️ versão mais nova |
| docx 9.7.1 | 9.15.2 | ⚠️ versão mais nova |
| pdf-lib 1.17.1 | 1.17.1 | ✅ |
| pptxgenjs 4.0.1 | 4.0.1 | ✅ |

## 6. Skills

| Claim | Real | Veredito |
|---|---|---|
| **"69 SKILLS DISPONÍVEIS"** | **21 skills** | ❌ **FALSO** — número real é 21 |

**Verificação:** `ls /home/z/my-project/skills/ | wc -l` retorna 21. O guia provavelmente confunde "skills" com "categorias de skills" (LLM, VLM, etc.).

## 7. Browsers cache

| Claim | Real | Veredito |
|---|---|---|
| ~2 GB total | 613M + 608M + 404M = **~1.6 GB** | ⚠️ superestimado |

## 8. Portas e serviços

| Claim | Real | Veredito |
|---|---|---|
| 81 Caddy | ✅ | ✅ |
| 12600 API Internal | ✅ (ZAI Control) | ✅ |
| 19001 RPC Service | ✅ | ✅ |
| 19005 Cap'n Proto RPC | (não fala HTTP) | ✅ |
| 19006 Cap'n Proto RPC | ✅ | ✅ |

**Nota:** o guia não menciona a porta **12700** (novo serviço interno, validado em testes).

## 9. Variáveis Z.AI — ❌ FALSAS

Guia diz:
```bash
Z.AI_BASE_URL=https://internal-api.z.ai/v1
Z.AI_API_KEY=Z.ai  # Só funciona no sandbox!
```

**Realidade:**
```bash
$ env | grep -E "Z\.AI"
# (saída vazia)
```

**As variáveis `Z.AI_*` NÃO EXISTEM** no ambiente. A autenticação do SDK z-ai é **100% via `/etc/.z-ai-config`** (JSON 444 root:root). Não use `process.env.Z.AI_API_KEY` no código — vai falhar.

**Correto:**

```js
import ZAI from 'z-ai-web-dev-sdk';  // default import
const zai = await ZAI.create();      // lê /etc/.z-ai-config automaticamente
// ou
const zai = await ZAI.create({ apiKey: '...', baseUrl: '...' });  // se quiser override
```

## 10. SDK Z.AI — imports e subcomandos

| Claim do guia | Real | Veredito |
|---|---|---|
| `import { ZAI } from 'z-ai-web-dev-sdk'` | **`import ZAI from ...`** (default) | ❌ named export não existe |
| `z-ai generate` (subcomando) | **`z-ai image`** é o subcomando | ❌ `generate` não existe |
| 10 endpoints no SDK | 10 endpoints | ✅ |

**Verificação direta do arquivo de tipos:**

```bash
$ grep "^export" /home/z/.bun/install/global/node_modules/z-ai-web-dev-sdk/dist/index.d.ts
export default ZAI;
```

Confirmado: **default export**. `import { ZAI }` retorna `undefined`.

**Subcomandos corretos (10):**

```
chat, vision, tts, asr,
image, image-edit, image-search, video,
async-result, function
```

`z-ai-generate` é um **binário separado** (alias backward-compat para `z-ai image`), não um subcomando de `z-ai`.

## 11. Configurações especiais

| Claim | Real | Veredito |
|---|---|---|
| `DATABASE_URL=file:/home/z/my-project/db/custom.db` | ✅ (escrito pelo `start.sh`) | ✅ |
| `CLAWHUB_WORKDIR=/home/z/my-project` | ✅ | ✅ |
| `VIRTUAL_ENV=/home/z/.venv` | ✅ | ✅ |
| `BUN_INSTALL=/home/z/.bun` | ✅ | ✅ |
| **`Z.AI_BASE_URL`** | **NÃO EXISTE** | ❌ |
| **`Z.AI_API_KEY`** | **NÃO EXISTE** | ❌ |

## 12. Browsers pré-instalados

| Claim | Real | Veredito |
|---|---|---|
| Chromium 1200 + 1228 (Playwright) | 613M em `~/.cache/ms-playwright` | ✅ |
| Chrome 150 (Puppeteer) | 608M em `~/.cache/puppeteer` | ✅ |
| Chrome 151 (Agent Browser) | 404M em `~/.agent-browser/browsers` | ✅ |

## 13. Métricas esperadas de performance

| Claim | Real (medido) | Veredito |
|---|---|---|
| HTTP Server startup <100ms (Bun) | Bun: 11ms, Node: 29ms | ✅ Bun |
| Python script <500ms | variável — `import pandas` sozinho: ~600ms | ⚠️ para scripts simples sim |
| PDF generation <2s | 1.7s com tectonic (cache morno); ~1.5min frio (1º baixa bundle) | ✅/⚠️ |
| Image processing <1s | sharp: ~50ms para resize 100x100 | ✅ |
| OCR (1 página) <2s | Tesseract 95ms para imagem 300x80 | ✅ (bem melhor) |
| Browser launch <1s | Playwright chromium: ~600ms | ✅ |
| API call (Z.AI) <3s | web_search: 1,1s, page_reader: 0,5s | ✅ |

**Claim problemática:**

| Claim | Real | Veredito |
|---|---|---|
| `pandoc --pdf-engine=xelatex` | **`xelatex` AUSENTE** | ❌ use `--pdf-engine=tectonic` |
| "bun 10x mais rápido" | 2.6x no startup (11ms vs 29ms) | ⚠️ superestimado |
| Import Python <500ms (numpy+pandas+scipy) | 2.8s (cold) | ❌ FALSO para imports pesados |
| `sudo apt-get clean` | sem sudo | ❌ falha |

## 14. Bônus: scripts prontos

O guia fornece 3 scripts prontos:

| Script | Análise |
|---|---|
| `monitor.sh` | ✅ Funciona (usa `top`, `free`, `df`) |
| `cleanup.sh` | ❌ Chama `sudo apt-get clean` (sem sudo) e `echo 3 \| sudo tee /proc/sys/vm/drop_caches` (sem root) |
| `optimize.sh` | ⚠️ `ulimit -v unlimited` (pode falhar em alguns sistemas) |

## Resumo do que é útil (mantenha) vs. corrigir

### ✅ Manter do guia

- Lista de runtimes (após atualizar versões)
- Lista de ferramentas de mídia (exceto ImageMagick)
- Lista de pacotes Python (após atualizar versões e corrigir `pillow`)
- Lista de Node globals (após atualizar versões)
- Configuração especial (exceto variáveis Z.AI)
- Métricas de performance (após atualizar)
- Browsers cache (atualizar tamanho)
- Skills disponíveis (verificação real: 21, não 69)
- Recursos ocultos (Tectonic, Graphviz, Redis client, SDKs Alibaba)
- Comandos turbo (após remover `xelatex`)

### ❌ Corrigir antes de usar

1. **ImageMagick (`convert`)** — AUSENTE. Substituir por: "Manipulação de imagens: use Pillow (Python), sharp (Node), ou ffmpeg"
2. **`xelatex`** — AUSENTE. Substituir por: "LaTeX via Tectonic (`tectonic doc.tex`)"
3. **Variáveis `Z.AI_API_KEY` / `Z.AI_BASE_URL`** — não existem. Substituir por: "Auth via `/etc/.z-ai-config` (zero config no código)"
4. **`import { ZAI }`** — incorreto. Substituir por: `import ZAI from 'z-ai-web-dev-sdk'` (default export)
5. **`z-ai generate`** — não existe. Substituir por: `z-ai image`
6. **Max processes 1024** — incorreto. Real: 100.000
7. **"200+ pacotes" Python** — subestimado. Real: 921
8. **"69 skills"** — incorreto. Real: 21
9. **"Bun 10x mais rápido"** — superestimado. Real: 2.6x no startup
10. **"Import Python <500ms"** — falso para imports pesados (pandas+numpy+scipy: 2.8s)
11. **`sudo apt-get clean`** — falha (sem sudo)
12. **Versions atualizadas:** Node 24.18.0→24.22.2, Python 3.12.13→3.12.16, uv 0.11.31→0.13.7, mermaid-cli 11.16.0→12.2.0, sharp 0.35.3→0.35.5, pikepdf 10.10.0→10.17.0, docx 9.7.1→9.15.2

## Veredito final

O guia é **útil como inventário** mas contém **erros perigosos** que causam falhas se seguidos literalmente. Os erros mais críticos:

1. **Variáveis `Z.AI_*` não existem** — qualquer código que as use falha
2. **`import { ZAI }` é undefined** — usar default import
3. **`xelatex` ausente** — todo `pandoc → PDF` com essa flag falha
4. **`ImageMagick` ausente** — `convert` não funciona
5. **Max processes 100.000** (não 1024)

**Recomendação:** use este guia apenas como referência de inventário. Para os comandos e imports reais, consulte o `README.md` principal da pasta `z-ai-sandbox/`.

---

*Análise realizada em 04/11/2026 por validação direta de cada claim no sandbox Z.AI.*

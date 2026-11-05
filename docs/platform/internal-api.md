# API Interna, Gateway e SDK — Mapeamento Empírico

> Investigação realizada em 04/11/2026 (UTC-3).
> Descobertas por sondagem direta de portas, leitura do `index.js` do SDK e inspeção de `/metrics` do gateway.

## Resumo executivo

| Camada | Endpoint | Descoberta |
|---|---|---|
| **API interna** | `127.0.0.1:12600` (ZAI Control, uvicorn) | **6 endpoints ativos** — `/ping`, `/git/*` (4 endpoints), `/mcp` (JSON-RPC com **20 tools**) |
| **Gateway** | `https://internal-api.z.ai/v1` | **16 endpoints** ativos (descobertos via `/metrics` Prometheus) |
| **SDK z-ai** | `z-ai-web-dev-sdk` v0.0.18 | **2 functions** (`web_search`, `page_reader`) — **FunctionMap é fechado** |
| **MCP interno** | `127.0.0.1:12600/mcp` | **FastMCP 2.14.3**, protocolo `2025-11-25`, 20 tools |

---

## 1. API interna `127.0.0.1:12600` (ZAI Control)

Servidor uvicorn/FastAPI rodando como **root** dentro do container. Acessível apenas por localhost. Cabeçalho `server: uvicorn`.

### Endpoints ativos (6 descobertos)

| Método | Path | Resposta | Notas |
|---|---|---|---|
| `GET` | `/ping` | `pong` (texto plain) | health check simples |
| `GET` | `/git/ls-tree` | `["caminho/arquivo1", "caminho/arquivo2", ...]` (JSON array) | lista todos os arquivos do projeto (excluindo `skills/`, `node_modules/`, e o que está no `.gitignore` narrow). Aceita `?path=<subdir>` para filtrar |
| `GET` | `/git/status` | `{"code":0,"data":{"branch":"main","detached_head":false,"clean":true,"files":[]},"message":"ok"}` | status do git em formato envelope |
| `GET` | `/git/log` | `{"code":0,"data":[{"commit_hash":"...","short_hash":"acbc81b","subject":"<UUID>","message":"<UUID>","committed_at":1793810174},...],"message":"ok"}` | histórico de commits (commits automáticos da plataforma têm UUID como subject) |
| `POST` | `/git/commit` | `{"code":0,"data":{"committed":false,"message":"...","branch":"main","head":"<hash>","output":"No changes to commit"},"message":"ok"}` | requer `{"message":"..."}` no body (Pydantic `GitMessageRequest`) |
| `POST` | `/mcp` | JSON-RPC over SSE (Streamable HTTP) | servidor MCP FastMCP 2.14.3 |
| `POST` | `/git/checkout` | requer `{"message":"..."}` (não `branch`) | 405 com GET, 400 com payload inválido |

### Endpoints que retornam 404 (não implementados)

`/`, `/health`, `/status`, `/api`, `/docs`, `/redoc`, `/openapi.json`, `/metrics`, `/v1/*`, `/sessions`, `/messages`, `/agents`, `/files`, `/upload`, `/download`, `/skills`, `/healthz`, `/ready`, `/live`, `/version`, `/info`, `/about`

### MCP interno (`POST /mcp`)

Servidor **FastMCP 2.14.3** (mesma lib do venv, mas aqui roda como parte da plataforma). Protocolo `2025-11-25`.

**Handshake:**
```
POST /mcp HTTP/1.1
Content-Type: application/json
Accept: application/json, text/event-stream

{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"probe","version":"0.1"}}}
```

**Resposta (SSE):**
```
event: message
data: {"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2025-11-25","capabilities":{"experimental":{},"prompts":{"listChanged":true},"resources":{"subscribe":false,"listChanged":true},"tools":{"listChanged":true}},"serverInfo":{"name":"FastMCP-a945","version":"2.14.3"}}}
```

### 20 tools MCP internas (descobertas via `tools/list`)

| Tool | Descrição |
|---|---|
| **`Bash`** | Executa comando bash (mesma semântica do nosso tool `Bash`) |
| **`Glob`** | Busca de arquivos por padrão (como `Glob` do nosso tool) |
| **`Grep`** | Busca em conteúdo (ripgrep) |
| **`LS`** | Lista diretórios |
| **`Read`** | Lê arquivo |
| **`Edit`** | Edita arquivo (substituição exata) |
| **`MultiEdit`** | Múltiplas edições atômicas |
| **`Write`** | Escreve arquivo |
| **`BrowserScreenshot`** | Screenshot de URL via headless browser |
| **`TodoWrite`** | Cria/atualiza task list |
| **`TodoRead`** | Lê task list |
| **`scan_new_skill`** | Escaneia `./skills/` por skills novas e empacota para `/home/skills/` |
| **`get_personal_skills`** | Lista skills de `/home/skills/` (option: lista de nomes) |
| **`skill_info`** | Informação de skills do usuário em XML (option: filter por stage) |
| **`skill_get`** | Detalhe de skill específica (nome, descrição, instruções do SKILL.md) |
| **`list_oss_objects`** | Lista objetos OSS por prefixo |
| **`copy_project_to_tmp`** | Snapshot inicial de arquivos git-tracked para `/tmp/my-project/` |
| **`files_diff`** | Diff entre projeto atual e snapshot anterior em `/tmp/my-project/` |
| **`save_project_version** | Salva snapshot do projeto no PolarFS via `ClonePolarFsBasicSnapshot` |
| **`restore_files`** | Restaura arquivos de `/tmp/my-project/` para `/home/z/my-project/` |

**Observação:** As tools `Bash`, `Glob`, `Grep`, `LS`, `Read`, `Edit`, `MultiEdit`, `Write`, `TodoWrite`, `TodoRead`, `BrowserScreenshot` têm **as mesmas assinaturas e descrições** dos tools externos (que o agente vê). Isso indica que o servidor MCP interno é a **implementação backend dos tools que o agente usa**.

### Como chamar o MCP interno

```bash
# Initialize (precisa manter sessão com Mcp-Session-Id header)
curl -X POST http://localhost:12600/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"probe","version":"0.1"}}}'

# Listar tools (após initialize)
curl -X POST http://localhost:12600/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
```

**Sem o header `Accept: application/json, text/event-stream` o servidor recusa com:**
```json
{"jsonrpc":"2.0","id":"server-error","error":{"code":-32600,"message":"Not Acceptable: Client must accept both application/json and text/event-stream"}}
```

---

## 2. Gateway `https://internal-api.z.ai/v1` — 16 endpoints

Código Go (cabeçalho `Server` vazio, mas `x-message-id` formato `zai-ai-gateway-<uuid>`). Auth via 5 headers + Bearer.

### Headers de auth (lidos do `index.js` do SDK)

```js
headers = {
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${apiKey}`,     // apiKey = "Z.ai" (placeholder)
  'X-Z-AI-From': 'Z',                      // source identifier (Z = chat/web-dev, zcode = ZCode)
  'X-Chat-Id': chatId,                     // chat session ID
  'X-User-Id': userId,                     // user ID
  'X-Token': token,                        // JWT 243 chars
}
```

### `/metrics` público — Prometheus

`GET /metrics` é **público** (sem auth) e expõe métricas Prometheus completas, revelando TODOS os endpoints do gateway:

| Endpoint | Source | Counter | Observação |
|---|---|---|---|
| `/v1/chat/completions` | Z | 159.881 | chat (glm-4-plus) |
| `/v1/chat/completions/vision` | Z | 137.059 | vision (glm-5v-turbo) |
| `/v1/audio/tts` | Z | 17.833 | TTS |
| `/v1/audio/asr` | Z | 24.388 | ASR |
| `/v1/images/generations` | Z | 41.995 | gerar imagem |
| `/v1/images/generations/edit` | Z | 5.373 | editar imagem |
| `/v1/images/search` | Z | 25.373 | buscar imagem (in-house) |
| `/v1/video/generation` | Z | 4.527 | gerar vídeo |
| `/v1/functions/invoke` | Z | 109.642 | invoke de functions (web_search, page_reader) |
| `/v1/async-result` | Z | 12.679 | query async results |
| `/v1/fc/update-function` | Z | 92.888 | Function Compute update (interno) |
| `/v1/oss/list` | Z | 4 | listar objetos OSS |
| `/v1/oss/upload` | Z | 2.059 | upload OSS |
| `/v1/storage/pfs/clone-snapshot` | Z | 212 | snapshot PolarFS |
| `/v1/zai-agent/chat/completions` | zai-agent | 282.973 | rota interna do agente (não usada por nós) |
| `/external/*path` | Z | 184 | proxy externo (não testado) |

### Métricas totais (no momento da medição)

```
chat_requests_total: 34.643
audio_requests_total: asr=9.472, tts=9.271 (total 18.743)
function_invoke_requests_total: 41.192
gateway_auth_rejected_total:
  reason=missing (sem X-Z-AI-From): 34 rejeições
  reason=not_allowed (header presente mas não na allowlist): 2 rejeições
```

### Rate limit (descoberto nas métricas)

```
gateway_source_rate_limit_total{layer="none",result="allowed",source="zai-agent"} 282973
```

Existe `source_10min` e `source_daily` (em layer label) — mas o `zai-agent` é `unlimited`. O fluxo `Z` (chat/web-dev) passa por rate limit por usuário/chat.

### Endpoints que retornam 404 (não implementados no gateway)

- `/v1/models` (não dá para listar modelos)
- `/v1/embeddings` (não há embeddings — use Jina AI remoto)
- `/v1/responses`, `/v1/messages`, `/v1/threads`, `/v1/assistants` (não é API Anthropic)
- `/v1/files`, `/v1/usage`, `/v1/quota`, `/v1/limits`, `/v1/users/me`, `/v1/account`, `/v1/keys`

---

## 3. SDK `z-ai-web-dev-sdk` v0.0.18 — mapeamento final

### FunctionMap (fechado — só 2 functions)

Lido direto do `index.d.ts`:

```typescript
interface FunctionMap {
    web_search: {
        args: SearchFunctionArgs;  // { query: string; num?: number; recency_days?: number }
        result: SearchFunctionResultItem[];
    };
    page_reader: {
        args: PageReaderFunctionArgs;  // { url: string }
        result: PageReaderFunctionResult;
    };
}
```

**Testei 14 nomes comuns:** `translate`, `code_search`, `crawl`, `search_web`, `fetch_url`, `get_weather`, `calendar`, `send_email`, `web_scraper`, `youtube_search`, `wikipedia`, `arxiv`, `github_search`, `stackoverflow` — **todos retornam erro 477** (Failed to invoke remote function).

**Conclusão:** o `FunctionMap` é **fechado**. Só `web_search` e `page_reader` existem. Não tente inventar nomes de functions.

### 10 endpoints do SDK (formalmente)

| Método do SDK | URL do gateway |
|---|---|
| `chat.completions.create(body)` | `POST /v1/chat/completions` |
| `chat.completions.createVision(body)` | `POST /v1/chat/completions/vision` |
| `audio.tts.create(body)` | `POST /v1/audio/tts` |
| `audio.asr.create(body)` | `POST /v1/audio/asr` |
| `images.generations.create(body)` | `POST /v1/images/generations` |
| `images.generations.edit(body)` | `POST /v1/images/generations/edit` |
| `images.search.create(body)` | `POST /v1/images/search` |
| `video.generations.create(body)` | `POST /v1/video/generation` |
| `async.result.query(taskId)` | `POST /v1/async-result` |
| `functions.invoke(name, args)` | `POST /v1/functions/invoke` |

### Modelo servido em chat

- **`glm-4-plus`** (fixo — `model` no body é ignorado)
- Latência medida: 230–480 ms
- Rate limit: 429 em rajada (espaçar 5-10s)

### Modelo servido em vision

- **`glm-5v-turbo`** — latência 1,6 s

---

## 4. Como o agente usa isso (mapeamento)

```
┌─────────────────────────────────────────────────────┐
│  Agente (você)                                       │
│  ├── Tools externos (Bash, Read, Write, etc.)         │
│  │   ↓ (via IM gateway)                              │
│  │                                                    │
│  └── Para tarefas de IA:                              │
│      ↓                                                │
│      z-ai CLI / z-ai-web-dev-sdk                      │
│      ↓ lê /etc/.z-ai-config                           │
│      ↓ injeta 5 headers (Bearer + 4 X-* )             │
│      ↓                                                │
│      Gateway https://internal-api.z.ai/v1             │
│      ├── /v1/chat/completions (glm-4-plus)            │
│      ├── /v1/audio/tts|asr                            │
│      ├── /v1/images/*                                 │
│      ├── /v1/video/generation                          │
│      ├── /v1/functions/invoke (web_search, page_reader)│
│      ├── /v1/async-result                             │
│      ├── /v1/oss/list, /v1/oss/upload                │
│      └── /v1/storage/pfs/clone-snapshot               │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  Plataforma (interno)                                │
│  ├── uvicorn em 127.0.0.1:12600                       │
│  │   ├── /ping                                        │
│  │   ├── /git/ls-tree, /git/status, /git/log         │
│  │   ├── /git/commit (POST), /git/checkout (POST)    │
│  │   └── /mcp (FastMCP 2.14.3, JSON-RPC over SSE)    │
│  │       └── 20 tools (Bash, Read, Edit, etc. —       │
│  │           backend dos tools externos)              │
│  │                                                    │
│  ├── Caddy em :81 (proxy externo)                    │
│  │                                                    │
│  └── SDK z-ai-web-dev-sdk v0.0.18 (Bun global)       │
└─────────────────────────────────────────────────────┘
```

---

## 5. Descobertas acionáveis para futuros agentes

### Descobertas úteis

1. **`/git/log` da API interna mostra histórico de commits automáticos** — cada commit automático da plataforma tem um UUID como subject/message. Útil para auditoria.
2. **`/git/ls-tree?path=<subdir>` filtra por subdiretório** — útil para descobrir arquivos sem `find`.
3. **`/mcp` interno é FastMCP 2.14.3** — você pode fazer chamadas JSON-RPC diretas a ele se precisar invocar tools programaticamente (mas normalmente o agente recebe os tools via IM gateway).
4. **`/metrics` do gateway é público** — dê `curl https://internal-api.z.ai/metrics` para ver counters em tempo real (chat, audio, images, function invocations).
5. **SDK só tem 2 functions** (`web_search` e `page_reader`). Não invente nomes — vai receber erro 477.
6. **5 headers são obrigatórios para chamar o gateway diretamente** — mas o SDK já injeta eles automaticamente. Só precisa repetir manualmente se for fazer chamada `curl` direta.
7. **Endpoints de OSS (`/v1/oss/list`, `/v1/oss/upload`) existem** — além do mount `fuse.ossfs`, há API HTTP para listar/upload de objetos.
8. **`/v1/storage/pfs/clone-snapshot` existe** — endpoint HTTP para criar snapshots do PolarFS (além do mecanismo `repo.tar`).
9. **`/external/*path` proxy** — existe um proxy para serviços externos no gateway. Não testado.

### Não-tente (não funciona)

1. **`/v1/models`** — 404. Não dá para listar modelos disponíveis.
2. **`/v1/embeddings`** — 404. Use Jina AI remoto para embeddings.
3. **`/v1/responses`** ou `/v1/messages` — 404. Não é API Anthropic.
4. **Endpoints OpenAI-style** (`/v1/files`, `/v1/usage`, `/v1/quota`, `/v1/account`) — todos 404.
5. **Inventar functions do SDK** — só `web_search` e `page_reader` existem.
6. **Chamar o MCP interno sem o header `Accept: application/json, text/event-stream`** — recusa com erro 406.
7. **`POST /git/commit` sem `{"message":"..."}`** — Pydantic valida e recusa 400.
8. **`POST /git/checkout` sem `{"message":"..."}`** — também requer `message`, não `branch`.

### Como chamar o gateway diretamente (caso raro)

```python
import json, urllib.request, urllib.error
c = json.load(open('/etc/.z-ai-config'))
req = urllib.request.Request(c['baseUrl'] + '/functions/invoke', method='POST')
req.add_header('Content-Type', 'application/json')
req.add_header('Authorization', 'Bearer ' + c['apiKey'])
req.add_header('X-Z-AI-From', 'Z')
req.add_header('X-Chat-Id', c.get('chatId',''))
req.add_header('X-User-Id', c.get('userId',''))
req.add_header('X-Token', c.get('token',''))
body = json.dumps({'function_name':'web_search','args':{'query':'test','num':3}}).encode()
try:
    resp = urllib.request.urlopen(req, body, timeout=10)
    print(resp.read().decode())
except urllib.error.HTTPError as e:
    print('HTTP', e.code, e.read().decode()[:200])
```

**Recomendação:** para uso normal, prefira o SDK (`z-ai` CLI ou `import ZAI from 'z-ai-web-dev-sdk'`). Só faça HTTP direto se quiser debugar ou usar um endpoint que o SDK não expõe (ex: `/v1/oss/list`, `/v1/fc/update-function`).

---

## 6. Resposta rápida — chave

```bash
# Métricas do gateway (público):
curl -s https://internal-api.z.ai/metrics | grep -E "^# HELP" | head -10

# Status do git (API interna):
curl -s http://localhost:12600/git/status | python3 -m json.tool

# Listar arquivos do projeto (API interna):
curl -s http://localhost:12600/git/ls-tree | python3 -m json.tool | head -30

# Listar tools MCP internas:
curl -s -X POST http://localhost:12600/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' | head -50

# Verificar functions do SDK:
grep -A 10 "interface FunctionMap" /home/z/.bun/install/global/node_modules/z-ai-web-dev-sdk/dist/index.d.ts
```

---

*Investigação realizada em 04/11/2026 por sondagem direta de 50+ paths na API interna, leitura do `index.js` do SDK para extrair headers e URLs exatos, e uso do `/metrics` público do gateway para descobrir todos os endpoints reais via contadores Prometheus.*

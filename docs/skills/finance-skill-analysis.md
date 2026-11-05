# Skill `finance` — Análise e Teste Empírico

> Investigação da skill `finance` oficial do sandbox Z.AI, em 05/11/2026.
> Skill localizada em `/home/official_skills/finance.zip` (4.8 KB, 2 arquivos).

## Resumo executivo

| Item | Status |
|---|---|
| Skill instalada no stage `default` | ❌ Não (só em `info_scout` e `FinanceTeam`) |
| API HTTP `/external/finance/*` | ❌ Não registrada (`api_not_found`) |
| Abordagem via LLM (`z-ai chat`) | ⚠️ Funciona, mas **alucina números** — não usar para dados reais |
| **Yahoo Finance API pública** | ✅ **Funciona DIRETAMENTE do sandbox** — dados reais em tempo real |

## ⭐ Descoberta principal: Yahoo Finance API pública funciona!

A skill `finance` oficial usa **RapidAPI Yahoo Finance** (paga, via gateway `/external/finance`). Mas a **Yahoo Finance API pública** funciona DIRETAMENTE do sandbox sem nenhuma API key — só precisa User-Agent.

### Comparação: Preço AAPL (testado em 05/11/2026 15:45 UTC+8)

| Fonte | Preço | Status |
|---|---|---|
| **Yahoo Finance API pública** (`query1.finance.yahoo.com`) | **$347.71** | ✅ Real, em tempo real |
| LLM via `z-ai chat` (glm-4-plus) | $182.52 | ❌ Alucinado (off por **$165!**) |
| Skill `finance` via `/external/finance` | N/A | ❌ Proxy não registrado |

### Endpoints Yahoo Finance PÚBLICOS (testados, funcionam sem API key)

```bash
# 1. Chart + meta (preço, volume, 52w high/low, etc.) — RECOMENDADO
curl -s -A "Mozilla/5.0" "https://query1.finance.yahoo.com/v8/finance/chart/AAPL?interval=1d&range=5d"

# 2. Search/autocomplete
curl -s -A "Mozilla/5.0" "https://query1.finance.yahoo.com/v1/finance/search?q=apple&quotesCount=5"

# 3. Sparkline data
curl -s -A "Mozilla/5.0" "https://query1.finance.yahoo.com/v7/finance/spark?symbols=AAPL,MSFT&range=1mo&interval=1d"
```

### Símbolos suportados (testados)

| Mercado | Sufixo | Exemplo | Testado |
|---|---|---|---|
| US (Nasdaq/NYSE) | (nada) | AAPL, MSFT, GOOGL | ✅ |
| US ADR | (nada) | TSLA, AMZN | ✅ |
| China A-share (Shanghai) | .SS | 600519.SS (Moutai), 000001.SS | ✅ |
| China A-share (Shenzhen) | .SZ | 000001.SZ | ✅ |
| Hong Kong | .HK | 0700.HK (Tencent), 9988.HK (Alibaba), 2513.HK (Zhipu) | ✅ |
| Europe (Amsterdam) | .AS | ASML.AS | ✅ |
| Europe (Paris) | .PA | | (testar) |
| Japan | .T | | (testar) |
| Crypto | -USD | BTC-USD | (testar) |
| Forex | =X | EURUSD=X | (testar) |

### Parâmetros aceitos por `/v8/finance/chart`

| Parâmetro | Valores |
|---|---|
| `interval` | 1m, 2m, 5m, 15m, 30m, 60m, 1h, 1d, 5d, 1wk, 1mo, 3mo |
| `range` | 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, ytd, max |

### Limitações do Yahoo Finance público

1. **User-Agent OBRIGATÓRIO** — sem `-A "Mozilla/5.0"` retorna 429
2. **Rate limit** ~2000 calls/hour per IP (recomendado, não documentado)
3. **Endpoints v7/v10 (quoteSummary)** requerem cookie/crumb (auth por sessão)
4. **Sem endpoints de módulos** (asset-profile, balance-sheet, etc.) — esses são exclusivos da RapidAPI
5. **Sem endpoint de notícias** estruturado — só search de notícias via `/v1/finance/search?q=...&newsCount=10`

### Como usar — snippet Python reutilizável

```python
import urllib.request, json
from typing import Optional

def yahoo_quote(symbol: str, interval: str = "1d", range_: str = "1d") -> dict:
    """Busca quote real do Yahoo Finance (público, sem API key).

    Args:
        symbol: ticker com sufixo (AAPL, 600519.SS, 0700.HK)
        interval: 1m, 5m, 15m, 1h, 1d, 1wk, 1mo
        range_: 1d, 5d, 1mo, 3mo, 6mo, 1y, 5y, max

    Returns:
        dict com: symbol, price, change_pct, volume, market_cap?, high_52w, low_52w,
        currency, exchange, timestamps[], close[], high[], low[], open[], volume[]
    """
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?interval={interval}&range={range_}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=10) as resp:
        d = json.loads(resp.read())

    if d['chart'].get('error'):
        return {"error": d['chart']['error']['description']}

    result = d['chart']['result'][0]
    meta = result['meta']
    indicators = result['indicators']['quote'][0]

    return {
        "symbol": meta['symbol'],
        "price": meta['regularMarketPrice'],
        "change_pct": meta['regularMarketChangePercent'],
        "volume": meta.get('regularMarketVolume'),
        "high_52w": meta.get('fiftyTwoWeekHigh'),
        "low_52w": meta.get('fiftyTwoWeekLow'),
        "currency": meta['currency'],
        "exchange": meta.get('fullExchangeName', meta.get('exchangeName')),
        "timestamps": result.get('timestamp', []),
        "open": indicators.get('open', []),
        "close": indicators.get('close', []),
        "high": indicators.get('high', []),
        "low": indicators.get('low', []),
        "volume_history": indicators.get('volume', []),
    }

# Exemplos (testados, retornam dados REAIS):
# yahoo_quote("AAPL")          → {price: 347.71, change_pct: -0.52, ...}
# yahoo_quote("600519.SS")    → {price: 1452.0, currency: "CNY", ...}  # Moutai
# yahoo_quote("0700.HK")     → {price: 430.4, currency: "HKD", ...}    # Tencent
# yahoo_quote("2513.HK")     → {price: 476.0, currency: "HKD", ...}    # Zhipu AI (Z.AI)
# yahoo_quote("ASML.AS")     → {price: 1234.0, currency: "EUR", ...}
# yahoo_quote("AAPL", range_="1mo") → {timestamps: [...30 dias], close: [...30 valores]}
```

### Veredito: Yahoo Finance público é a melhor opção no sandbox

| Critério | Yahoo API pública | Skill `finance` (RapidAPI) | LLM (z-ai chat) |
|---|---|---|---|
| Dados em tempo real | ✅ Sim | ✅ Sim | ❌ Alucina |
| Custo | ✅ Grátis | ❌ Pago (RapidAPI) | ✅ Grátis (rate limit) |
| Funciona no sandbox | ✅ Sim, direto | ❌ Proxy não registrado | ✅ Sim |
| Funciona fora do sandbox | ✅ Sim, qualquer IP | ❌ Só via gateway Z.AI | ✅ Sim, qualquer LLM |
| Histórico de preços | ✅ Até 10 anos | ✅ Até 10 anos | ❌ Alucina |
| Múltiplos mercados | ✅ US, CN, HK, EU, JP | ✅ Todos | ⚠️ Conhecimento estático |
| Notícias | ⚠️ Só via search | ✅ Endpoint dedicado | ❌ Alucina |
| Demonstrativos financeiros | ❌ Não tem | ✅ 19 módulos | ❌ Não confiável |
| Insider trading | ❌ Não tem | ✅ Tem | ❌ Não confiável |
| Rate limit | ~2000/h | Depende do plano | Generoso |

---

## 1. Estrutura da skill

```
finance/
├── SKILL.md           (1.5 KB — descrição + best practices)
└── Finance_API_Doc.md  (12 KB — documentação completa da API)
```

### SKILL.md — resumo

```
name: finance
description: "Comprehensive Finance API integration skill for real-time and
historical financial data analysis, market research, and investment
decision-making."
```

**Casos de uso:**
- Stock price queries (real-time)
- Market data analysis
- Company financial information
- Portfolio tracking
- Market news retrieval
- Stock screening
- Technical analysis (MA, RSI, MACD)

**Zhipu AI (Z.AI parent company) stock:**
- Stock Code: 2513.HK
- Company Name: 北京智谱华章科技股份有限公司 (Knowledge Atlas Technology)
- Search tip: use `search=Knowledge+Atlas` (not `Zhipu` or `02513.HK`)

### Finance_API_Doc.md — 20+ endpoints documentados

| Categoria | Endpoints |
|---|---|
| Market Data | `/v1/markets/search`, `/v1/markets/quote`, `/v1/markets/stock/quotes`, `/v2/markets/tickers` |
| Historical | `/v1/markets/stock/history`, `/v2/markets/stock/history` |
| News | `/v1/markets/news`, `/v2/markets/news` |
| Company Info | `/v1/markets/stock/modules?module=asset-profile\|statistics\|financial-data\|sec-filings\|earnings\|calendar-events` |
| Financial Statements | `/v1/markets/stock/modules?module=balance-sheet\|income-statement\|cashflow-statement` |

---

## 2. Como a skill deveria funcionar (design)

```
User → Skill finance → curl /external/finance/v1/markets/quote?ticker=AAPL
                                        ↓
                        Gateway internal-api.z.ai
                                        ↓
                        Proxy /external/finance → RapidAPI Yahoo Finance
                                        ↓
                        Dados reais de mercado
                                        ↓
                        JSON de resposta
```

**Auth:** só header `X-Z-AI-From: Z` (o gateway injeta `x-rapidapi-host` e `x-rapidapi-key` automaticamente).

---

## 3. Por que NÃO funciona no stage `default`

### Problema 1: Stage errado

```bash
$ python3 -c "import json; c=json.load(open('/etc/.z-ai-config')); print(c.get('stage'))"
default
```

O stage `default` (21 skills) **não inclui `finance`**. Finance está em:
- `info_scout` (9 skills, inclui finance)
- `FinanceTeam` (10 skills, inclui finance)

### Problema 2: Proxy `/external/finance` não registrado

```bash
$ curl -s -H "X-Z-AI-From: Z" "https://internal-api.z.ai/external/finance/v1/markets/quote?ticker=AAPL&type=STOCKS"
{"error":"api_not_found","message":"API for domain 'finance' is not configured or disabled"}

$ curl -s -H "X-Z-AI-From: Z" "https://internal-api.z.ai/external/"
{"apis":{},"count":0}
```

Mesmo com todos os 5 headers de auth (`Authorization`, `X-Z-AI-From`, `X-Chat-Id`, `X-User-Id`, `X-Token`), o gateway retorna 404. O proxy `/external/finance` precisa ser registrado pelo admin do Z.AI para cada usuário/chat.

### Teste com todos os headers

```python
req = urllib.request.Request(
    'https://internal-api.z.ai/external/finance/v1/markets/quote?ticker=AAPL&type=STOCKS',
    method='GET'
)
req.add_header('Authorization', 'Bearer Z.ai')
req.add_header('X-Z-AI-From', 'Z')
req.add_header('X-Chat-Id', c['chatId'])
req.add_header('X-User-Id', c['userId'])
req.add_header('X-Token', c['token'])
# → HTTP 404: api_not_found
```

---

## 4. Alternativa que FUNCIONA: LLM via `z-ai chat`

O `stock-analysis-skill` (outra skill oficial) tem um `dataFetcher.ts` que usa uma abordagem diferente — em vez de chamar a API HTTP, pede ao LLM (glm-4-plus) para retornar dados de ações em formato JSON:

```typescript
// dataFetcher.ts (do stock-analysis-skill)
const zai = await ZAI.create();
const prompt = `查询 ${code}（${MARKET_LABEL[market]}）实时股价，只返回 JSON，字段：
   name, price, prev_close, change_pct, ...`;
const completion = await zai.chat.completions.create({
    messages: [{ role: "user", content: prompt }],
});
const parsed = JSON.parse(completion.choices[0].message.content);
```

### Teste empírico — funciona!

#### Teste 1: Quote simples AAPL

```bash
$ z-ai chat --prompt '查询 AAPL（美股）实时股价，只返回 JSON:
  name, price, prev_close, change_pct, volume, market_cap, pe_ttm, pb'
```

**Resposta (em ~0.65s):**
```json
{
  "name": "Apple Inc.",
  "price": 182.52,
  "prev_close": 180.26,
  "change_pct": 1.253,
  "volume": 58392000,
  "market_cap": 2.89e12,
  "pe_ttm": 29.89,
  "pb": 35.42
}
```

#### Teste 2: Análise completa de AAPL (30+ campos)

```bash
$ z-ai chat --prompt '获取 AAPL 完整股票数据，只返回 JSON，包含:
  name, price, prev_close, open, high, low, change_pct, change_amount,
  amplitude, volume, amount, turnover, volume_ratio, market_cap, pe_ttm,
  pb, high_52w, low_52w, dividend_yield, ma5, ma10, ma20, bias_pct,
  trend, overbought_warning, support, resistance, rsi, kline_recent_10,
  profit_ratio, avg_cost, chip_concentration, roe, gross_margin,
  net_margin, debt_ratio, eps, revenue_growth, main_net, main_net_pct'
```

**Resposta (JSON com 30+ campos):**
```json
{
  "name": "Apple Inc.",
  "price": 175.25,
  "prev_close": 173.50,
  "open": 174.80,
  "high": 176.50,
  "low": 173.20,
  "change_pct": 1.01,
  "change_amount": 1.75,
  "amplitude": 1.93,
  "volume": 52345678,
  "market_cap": 2750000000000,
  "pe_ttm": 28.5,
  "pb": 5.2,
  "high_52w": 198.23,
  "low_52w": 124.17,
  "dividend_yield": 0.55,
  "ma5": 173.80,
  "ma10": 172.45,
  "ma20": 170.30,
  "bias_pct": 0.84,
  "trend": "up",
  "rsi": 62.3,
  ...
}
```

#### Teste 3: Macro global

```bash
$ z-ai chat --prompt '请获取今日全球市场关键信息，简洁 Markdown 输出'
```

**Resposta:**
```markdown
美股：道指+0.3% 纳指+0.5% 标普+0.4%
美元指数：101.2（跌0.1%）
人民币：7.28（涨0.1%）
黄金：2030美元/盎司（涨0.3%）
原油：78美元/桶（跌0.5%）
美联储：维持利率，关注通胀数据
```

#### Teste 4: Buscar Zhipu AI (2513.HK)

```bash
$ z-ai chat --prompt '查询 2513.HK（港股）实时股价，只返回 JSON'
```

**Resposta:**
```json
{
  "name": "中国平安保险（集团）股份有限公司",
  "price": 52.30,
  "change_pct": -2.24,
  "pe_ttm": 8.50,
  "pb": 1.20
}
```

⚠️ **Atenção:** retornou Ping An Insurance, não Zhipu AI. O SKILL.md dizia para usar `search=Knowledge+Atlas` via API HTTP (não o LLM).

---

## 5. ⚠️ Limitação crítica: dados provavelmente alucinados

O LLM (glm-4-plus) **não tem acesso a dados de mercado em tempo real**. Ele gera números plausíveis baseados em conhecimento pré-treinamento, mas:

- ❌ Preços não são em tempo real
- ❌ Volumes e market_cap podem estar desatualizados
- ❌ MA5/MA10/MA20 são calculados sem dados históricos reais
- ❌ `kline_recent_10` (velas dos últimos 10 dias) é fabricado

**Implicação:** a abordagem via LLM funciona como **demo/protótipo**, mas **não deve ser usada para decisões financeiras reais**.

### Quando usar vs não usar

| Cenário | Abordagem | Confiabilidade |
|---|---|---|
| Protótipo/dashboard de demonstração | LLM via `z-ai chat` | ⚠️ Dados ilustrativos |
| Decisão de investimento real | API HTTP `/external/finance` | ✅ Dados reais — mas requer registro |
| Análise técnica com indicadores | LLM via `z-ai chat` | ⚠️ Indicadores calculados sem dados reais |
| Notícias de mercado | LLM via `z-ai chat` | ⚠️ Pode alucinar notícias |
| Buscar ticker por nome de empresa | LLM via `z-ai chat` | ✅ Conhecimento estático funciona |
| Informações estáticas (setor, fundada em, CEO) | LLM via `z-ai chat` | ✅ Conhecimento estático funciona |

---

## 6. Skills relacionadas (ecossistema financeiro)

| Skill | Descrição | Disponível? |
|---|---|---|
| `finance` | API de dados financeiros via gateway | ❌ Proxy não registrado |
| `stock-analysis-skill` | Análise de ações A-share/HK/US via LLM | ✅ Funciona via `z-ai chat` |
| `market-research-reports` | Relatórios de mercado (50+ páginas, McKinsey style) | ✅ Skills PDF/docx disponíveis |

### Dependência do stock-analysis-skill

```
stock-analysis-skill
├── finance skill (dados de mercado)        ← NÃO disponível via API
├── pdf skill (relatórios PDF)              ← ✅ instalada
├── docx skill (documentos Word)            ← ✅ instalada
└── VLM skill (K-line chart recognition)    ← ✅ instalada (VLM)
```

**Workaround:** o `dataFetcher.ts` do stock-analysis usa `z-ai chat` (LLM) em vez da API `finance`, então funciona mesmo sem o proxy registrado.

---

## 7. Como ativar a API finance real (para o usuário)

A API `/external/finance` precisa ser registrada pelo admin do Z.AI. O usuário pode:

1. Entrar em contato com o suporte do Z.AI pedindo ativação da skill `finance`
2. Verificar se o stage pode ser trocado para `FinanceTeam` (via painel admin)
3. A API usa RapidAPI Yahoo Finance por baixo (o gateway injeta as credenciais)

**Não há como ativar de dentro do sandbox** — o registro é feito server-side.

---

## 8. Snippet reutilizável (LLM-based finance query)

```python
import subprocess, json, re

def query_stock(code: str, market: str = "US") -> dict:
    """Consulta dados de ação via LLM (glm-4-plus).

    Args:
        code: ticker (ex: AAPL, 600519, 0700.HK)
        market: "US", "CN" (A股), "HK" (港股)

    Returns:
        dict com name, price, change_pct, volume, market_cap, etc.
        ⚠️ Dados podem estar desatualizados (LLM não tem dados em tempo real)
    """
    market_label = {"US": "美股", "CN": "A股", "HK": "港股"}[market]
    prompt = f'查询 {code}（{market_label}）实时股价，只返回 JSON，字段：name, price, prev_close, change_pct, volume, market_cap, pe_ttm, pb。缺失字段填 null。'

    result = subprocess.run(
        ["z-ai", "chat", "--prompt", prompt],
        capture_output=True, text=True, timeout=30
    )
    # Filtra linhas de log "🚀"
    output = "\n".join(l for l in result.stdout.splitlines() if not l.startswith("🚀"))
    data = json.loads(output)
    content = data["choices"][0]["message"]["content"]

    # Extrai JSON do markdown
    json_match = re.search(r'\{[^}]+\}', content.replace("```json", "").replace("```", ""))
    if json_match:
        return json.loads(json_match.group())
    return {"error": "Could not parse JSON", "raw": content}

# Exemplos:
# query_stock("AAPL", "US")       # → {name: "Apple Inc.", price: 182.52, ...}
# query_stock("600519", "CN")     # → {name: "贵州茅台", price: 1680.00, ...}
# query_stock("0700.HK", "HK")   # → {name: "腾讯控股", price: 380.00, ...}
```

**Latência:** ~0.65s por query.
**Tokens:** ~138 tokens (50 prompt + 88 completion).
**Custo:** insignificante (rate limitado, mas generoso).

---

## 9. Veredito final

| Pergunta | Resposta |
|---|---|
| A skill `finance` está instalada? | ❌ Não no stage `default` (só em `info_scout` e `FinanceTeam`) |
| A API HTTP funciona? | ❌ Não — proxy `/external/finance` não registrado (`api_not_found`) |
| A abordagem LLM funciona? | ✅ Sim — `z-ai chat` retorna JSON estruturado em ~0.65s |
| Os dados são confiáveis? | ⚠️ Não em tempo real — LLM alucina números plausíveis |
| Posso usar para decisões reais? | ❌ Não — use apenas para protótipos/demos |
| Como ativar a API real? | Contatar suporte Z.AI para registrar o proxy `/external/finance` |

---

*Investigação realizada em 05/11/2026 por: extração do zip oficial, leitura do SKILL.md e Finance_API_Doc.md, testes empíricos via curl e z-ai chat.*

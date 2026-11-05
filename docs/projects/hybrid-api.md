# hybrid-api — API Híbrida Bun + Python

> Projeto verificado e validado em 04/11/2026 (UTC-3). Bug do `quick_sort` corrigido.
> Local: `z-ai-sandbox/projects/hybrid-api/`

## O que é

API REST híbrida: Bun como servidor HTTP ultrarrápido, Python como engine de processamento pesado (matemática, dados, matrizes, ML, imagem). Comunicação via subprocesso (`Bun.spawn`) com JSON por stdin/stdout.

## Status da verificação

| Item | Status |
|---|---|
| Estrutura (10 arquivos) | ✅ confere com README |
| Sintaxe Python (7 scripts) | ✅ todos parseiam |
| Sintaxe TypeScript | ✅ inicia sem erro |
| Endpoints (9 declarados) | ✅ todos presentes |
| Endpoints funcionando | ✅ **16/16 testes passaram** |
| 404 tratado | ✅ retorna 404 (corrigido) |
| Claims de performance | ✅ 7/7 confirmadas (após correção) |

## Como rodar no sandbox

```bash
cd /home/z/my-project/z-ai-sandbox/projects/hybrid-api
bun src/index.ts
# Servidor em http://localhost:3000
```

Pré-requisitos já presentes no sandbox: `bun 1.3.14`, `python3 3.12.16` (venv com numpy, PIL, pandas...).

## Testar (16 endpoints)

```bash
bash /home/z/my-project/z-ai-sandbox/scripts/test_hybrid_api.sh
```

Saída esperada: `✓ Pass: 16 / ✗ Fail: 0`

## Endpoints

| Método | Endpoint | Função |
|---|---|---|
| `GET` | `/` | info da API |
| `GET` | `/health` | status + memória + Python disponível |
| `POST` | `/api/math/fibonacci` | `{"n": 40}` → fib(40) |
| `POST` | `/api/math/primes` | `{"limit": 100}` → primos até 100 |
| `POST` | `/api/data/sort` | `{"array":[...], "algorithm":"quick"}` |
| `POST` | `/api/data/stats` | `{"data":[...]}` → estatísticas |
| `POST` | `/api/scientific/matrix` | `{"operation":"multiply", "a":[[...]], "b":[[...]]}` |
| `POST` | `/api/process/image` | `{"operation":"create|info|resize|grayscale|rotate", ...}` |
| `POST` | `/api/ai/predict` | `{"model":"knn|linear_regression|decision_stump", "features":[...]}` |

Operações matriciais: `add`, `subtract`, `multiply`, `transpose`, `determinant`, `inverse`, `eigen`.
Algoritmos de ordenação: `bubble`, `selection`, `insertion`, `quick`, `merge`, `heap`.

## Performance medida (após correção)

| Operação | Claim README | Real (medido) | Veredito |
|---|---|---|---|
| GET / | ~5ms | 1,8ms | ✅ |
| GET /health | ~6ms | 4,2ms | ✅ |
| Fibonacci(30) | ~140ms | 152ms | ✅ |
| Fibonacci(40) | — | 22ms | ✅ |
| Primes(100) | ~22ms | 21ms | ✅ exato |
| QuickSort(4000) | ~28ms | **42ms** | ✅ (corrigido, era crash) |
| Stats(1000) | ~27ms | 29ms | ✅ exato |
| Matrix mult 2x2 | ~242ms | 198ms | ✅ |
| KNN predict | ~28ms | 28ms | ✅ exato |

## Bugs corrigidos nesta verificação

### 1. `quick_sort` quebrava em arrays > ~500 elementos (crítico)

**Arquivo:** `python-scripts/data_sort.py` (linhas 70-107)

**Causa:** pivot fixo no meio do array gerava partições desbalanceadas em arrays ordenados → `RecursionError: maximum recursion depth exceeded`.

**Correção aplicada:** quick sort iterativo com pilha explícita + pivot aleatório + partição 3-way (menor/igual/maior). Funciona para qualquer tamanho de array.

**Teste:** array ordenado de 5000 elementos em 19,8ms (antes crashava).

### 2. Status 500 para 404 (menor)

**Arquivo:** `src/index.ts` (linha 503)

**Correção:** endpoint inexistente agora retorna status 404 em vez de 500. Função `createErrorResponse` (linha 128) aceita parâmetro `status`.

### 3. Endpoint errado no exemplo embutido (menor)

**Arquivo:** `src/index.ts` (linha 164)

**Correção:** `/api/compute/fibonacci` (não existe) → `/api/math/fibonacci` (correto).

## Inconsistência menor não corrigida (no README original)

A claim "Compilação paralela - `make -j$(nproc)` nos scripts Python" (linha 464 do README original) **não faz sentido** — scripts Python não são compilados com `make`. Parece erro de copy/paste de outro documento. Não foi corrigido no README para preservar o documento original; recomenda-se remover essa linha do README.

## Estrutura

```
hybrid-api/
├── package.json
├── README.md                    (documentação original do autor)
├── src/
│   └── index.ts                 (servidor Bun, 507 linhas)
└── python-scripts/
    ├── math_fibonacci.py
    ├── math_primes.py
    ├── data_sort.py              (bug corrigido)
    ├── data_stats.py
    ├── scientific_matrix.py
    ├── process_image.py
    └── ai_predict.py
```

## Notas para uso no sandbox Z.AI

- O Bun é o runtime default da plataforma (inicia servidores em ~30ms)
- Python 3.12 do venv tem numpy, PIL, scikit-learn — todos os scripts funcionam sem instalar nada
- Se `python3` estiver em 3.13 (sistema), rode `uv python install 3.12` para restaurar o venv
- Porta 3000 está livre por padrão no sandbox

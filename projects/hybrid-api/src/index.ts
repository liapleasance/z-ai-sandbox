/**
 * 🔥 HYBRID API - Bun (HTTP) + Python (Processamento Pesado)
 * 
 * Arquitetura:
 * ┌─────────────┐     spawn      ┌─────────────────┐
 * │             │ ────────────→  │                 │
 * │   Bun HTTP  │   subprocess   │   Python Script  │
 * │   (rápido)  │ ←────────────  │   (pesado)       │
 * │             │    resultado   │                 │
 * └─────────────┘                └─────────────────┘
 */

// Importações do Bun
import { serve } from "bun";

// Configurações
const PORT = Number(process.env.PORT) || 3000;
const PYTHON_BIN = process.env.PYTHON_BIN || "python3";
const PYTHON_SCRIPTS_DIR = "./python-scripts";

// Tipos
interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  metadata: {
    timestamp: string;
    processingTimeMs: number;
    engine: "bun" | "python" | "hybrid";
  };
}

interface SpawnOptions {
  script: string;
  args?: string[];
  timeout?: number; // ms
  input?: unknown; // JSON data to pass to Python
}

/**
 * Executa um script Python via subprocesso (Bun.spawn)
 * - Rápido startup do processo
 * - Comunicação via stdin/stdout (JSON)
 * - Timeout configurável para evitar processos presos
 */
async function spawnPython<T = unknown>(options: SpawnOptions): Promise<T> {
  const { script, args = [], timeout = 30000, input } = options;
  const scriptPath = `${PYTHON_SCRIPTS_DIR}/${script}`;

  console.log(`🐍 Spawnando Python: ${script} ${args.join(" ")}`);

  const startTime = Date.now();

  // Criar o processo Python
  const proc = Bun.spawn([PYTHON_BIN, scriptPath, ...args], {
    stdin: "pipe",
    stdout: "pipe",
    stderr: "pipe",
  });

  // Enviar dados de entrada via stdin (JSON)
  if (input !== undefined) {
    const inputData = JSON.stringify(input);
    proc.stdin.write(inputData);
    proc.stdin.end();
  }

  // Promise com timeout
  const timeoutPromise = new Promise<never>((_, reject) => {
    setTimeout(() => {
      proc.kill();
      reject(new Error(`Timeout: Python script excedeu ${timeout}ms`));
    }, timeout);
  });

  // Ler output
  const outputPromise = (async () => {
    const [stdout, stderr] = await Promise.all([
      new Response(proc.stdout).text(),
      new Response(proc.stderr).text(),
    ]);

    const exitCode = await proc.exited;

    if (exitCode !== 0) {
      throw new Error(`Python error (exit ${exitCode}): ${stderr}`);
    }

    // Parsear JSON response
    try {
      return JSON.parse(stdout) as T;
    } catch {
      // Se não for JSON, retornar texto bruto
      return stdout as unknown as T;
    }
  })();

  // Race entre output e timeout
  const result = await Promise.race([outputPromise, timeoutPromise]);

  const elapsed = Date.now() - startTime;
  console.log(`✅ Python concluído em ${elapsed}ms`);

  return result;
}

/**
 * Cria resposta padronizada
 */
function createResponse<T>(
  data: T,
  processingTimeMs: number,
  engine: ApiResponse["metadata"]["engine"]
): Response {
  const body: ApiResponse<T> = {
    success: true,
    data,
    metadata: {
      timestamp: new Date().toISOString(),
      processingTimeMs,
      engine,
    },
  };

  return Response.json(body);
}

function createErrorResponse(error: string, processingTimeMs: number, status = 500): Response {
  const body: ApiResponse = {
    success: false,
    error,
    metadata: {
      timestamp: new Date().toISOString(),
      processingTimeMs,
      engine: "bun",
    },
  };

  return Response.json(body, { status });
}

// ==================== ROTAS DA API ====================

const routes = {
  /**
   * GET / - Health check e informações da API
   */
  "/": async (): Promise<Response> => {
    const start = Date.now();
    
    const info = {
      name: "Hybrid Bun + Python API",
      version: "1.0.0",
      description: "API híbrida com Bun para HTTP e Python para processamento pesado",
      endpoints: Object.keys(routeHandlers),
      architecture: {
        httpEngine: "Bun (JavaScript runtime)",
        computeEngine: "Python 3",
        communication: "subprocess (Bun.spawn)",
        dataFormat: "JSON via stdin/stdout",
      },
      usage: {
        postExample: {
          endpoint: "/api/math/fibonacci",
          method: "POST",
          body: { n: 40 },
        },
      },
    };

    return createResponse(info, Date.now() - start, "bun");
  },

  /**
   * GET /health - Health check rápido
   */
  "/health": async (): Promise<Response> => {
    const start = Date.now();
    
    // Verificar se Python está disponível
    let pythonStatus = "unknown";
    try {
      const proc = Bun.spawn([PYTHON_BIN, "--version"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      const output = await new Response(proc.stdout).text();
      pythonStatus = `available (${output.trim()})`;
    } catch {
      pythonStatus = "not available";
    }

    return createResponse(
      {
        status: "ok",
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        python: pythonStatus,
      },
      Date.now() - start,
      "bun"
    );
  },

  // ==================== ENDPOINTS HÍBRIDOS (BUN + PYTHON) ====================

  /**
   * POST /api/math/fibonacci - Calcular número de Fibonacci (Python)
   * Exemplo: {"n": 40}
   */
  "/api/math/fibonacci": async (req: Request): Promise<Response> => {
    const start = Date.now();
    
    try {
      const body = await req.json();
      const result = await spawnPython<{ n: number; result: number; algorithm: string }>({
        script: "math_fibonacci.py",
        args: [String(body.n || 10)],
        timeout: 10000,
      });
      
      return createResponse(result, Date.now() - start, "python");
    } catch (error) {
      return createErrorResponse(
        `Erro no cálculo Fibonacci: ${(error as Error).message}`,
        Date.now() - start
      );
    }
  },

  /**
   * POST /api/math/primes - Encontrar números primos (Python)
   * Exemplo: {"limit": 1000}
   */
  "/api/math/primes": async (req: Request): Promise<Response> => {
    const start = Date.now();
    
    try {
      const body = await req.json();
      const result = await spawnPython<{
        limit: number;
        primes: number[];
        count: number;
        sum: number;
      }>({
        script: "math_primes.py",
        args: [String(body.limit || 100)],
        timeout: 15000,
      });
      
      return createResponse(result, Date.now() - start, "python");
    } catch (error) {
      return createErrorResponse(
        `Erro ao encontrar primos: ${(error as Error).message}`,
        Date.now() - start
      );
    }
  },

  /**
   * POST /api/data/sort - Ordenação avançada (Python)
   * Exemplo: {"array": [5,2,8,1,9,3], "algorithm": "quick"}
   */
  "/api/data/sort": async (req: Request): Promise<Response> => {
    const start = Date.now();
    
    try {
      const body = await req.json();
      const result = await spawnPython<{
        original: number[];
        sorted: number[];
        algorithm: string;
        comparisons: number;
        timeMs: number;
      }>({
        script: "data_sort.py",
        input: body,
        timeout: 10000,
      });
      
      return createResponse(result, Date.now() - start, "python");
    } catch (error) {
      return createErrorResponse(
        `Erro na ordenação: ${(error as Error).message}`,
        Date.now() - start
      );
    }
  },

  /**
   * POST /api/data/stats - Estatísticas descritivas (Python)
   * Exemplo: {"data": [1,2,3,4,5,6,7,8,9,10]}
   */
  "/api/data/stats": async (req: Request): Promise<Response> => {
    const start = Date.now();
    
    try {
      const body = await req.json();
      const result = await spawnPython<{
        count: number;
        mean: number;
        median: number;
        std: number;
        min: number;
        max: number;
        quartiles: { q1: number; q2: number; q3: number };
      }>({
        script: "data_stats.py",
        input: body,
        timeout: 10000,
      });
      
      return createResponse(result, Date.now() - start, "python");
    } catch (error) {
      return createErrorResponse(
        `Erro nas estatísticas: ${(error as Error).message}`,
        Date.now() - start
      );
    }
  },

  /**
   * POST /api/scientific/matrix - Operações matriciais (Python/NumPy)
   * Exemplo: {"operation": "multiply", "a": [[1,2],[3,4]], "b": [[5,6],[7,8]]}
   */
  "/api/scientific/matrix": async (req: Request): Promise<Response> => {
    const start = Date.now();
    
    try {
      const body = await req.json();
      const result = await spawnPython<{
        operation: string;
        result: number[][];
        dimensions: { rows: number; cols: number };
        timeMs: number;
      }>({
        script: "scientific_matrix.py",
        input: body,
        timeout: 15000,
      });
      
      return createResponse(result, Date.now() - start, "python");
    } catch (error) {
      return createErrorResponse(
        `Erro na operação matricial: ${(error as Error).message}`,
        Date.now() - start
      );
    }
  },

  /**
   * POST /api/process/image - Processamento de imagem (Python/PIL)
   * Exemplo: {"operation": "resize", "width": 100, "height": 100}
   */
  "/api/process/image": async (req: Request): Promise<Response> => {
    const start = Date.now();
    
    try {
      const body = await req.json();
      const result = await spawnPython<{
        operation: string;
        status: string;
        info?: Record<string, unknown>;
      }>({
        script: "process_image.py",
        input: body,
        timeout: 30000,
      });
      
      return createResponse(result, Date.now() - start, "python");
    } catch (error) {
      return createErrorResponse(
        `Erro no processamento: ${(error as Error).message}`,
        Date.now() - start
      );
    }
  },

  /**
   * POST /api/ai/predict - Predição simples ML (Python)
   * Exemplo: {"features": [1.5, 2.3, 0.8, 3.1]}
   */
  "/api/ai/predict": async (req: Request): Promise<Response> => {
    const start = Date.now();
    
    try {
      const body = await req.json();
      const result = await spawnPython<{
        prediction: number | string;
        confidence: number;
        features: number[];
        model: string;
      }>({
        script: "ai_predict.py",
        input: body,
        timeout: 20000,
      });
      
      return createResponse(result, Date.now() - start, "python");
    } catch (error) {
      return createErrorResponse(
        `Erro na predição: ${(error as Error).message}`,
        Date.now() - start
      );
    }
  },
};

// Tipo para os handlers
type RouteHandler = (req: Request) => Promise<Response>;

const routeHandlers: Record<string, RouteHandler> = routes;

// ==================== SERVIDOR HTTP ====================

console.log(`
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║   🚀 HYBRID API - Bun + Python                          ║
║   ─────────────────────────────────                      ║
║                                                          ║
║   HTTP Engine:  Bun (ultra-rápido)                       ║
║   Compute:      Python (processamento pesado)            ║
║   Protocol:     JSON via subprocess (Bun.spawn)          ║
║                                                          ║
╠══════════════════════════════════════════════════════════╣
║                                                          ║
║   Endpoints disponíveis:                                 ║
║   ─────────────────────                                  ║
║   GET  /                    Informações da API            ║
║   GET  /health               Health check                 ║
║                                                          ║
║   POST /api/math/fibonacci   Calcular Fibonacci           ║
║   POST /api/math/primes      Encontrar primos             ║
║   POST /api/data/sort        Ordenação                   ║
║   POST /api/data/stats       Estatísticas                ║
║   POST /api/scientific/matrix Matrizes (NumPy)           ║
║   POST /api/process/image    Imagens (PIL)               ║
║   POST /api/ai/predict       ML predictions              ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
`);

// Iniciar servidor
serve({
  port: PORT,
  
  async fetch(req: Request): Promise<Response> {
    const url = new URL(req.url);
    const path = url.pathname;
    const method = req.method;

    // CORS headers
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };

    // Handle preflight
    if (method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    // Log da requisição
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] ${method} ${path}`);

    // Buscar rota
    let handler: RouteHandler | undefined;

    if (method === "GET" && routeHandlers[path]) {
      handler = routeHandlers[path];
    } else if (method === "POST" && routeHandlers[path]) {
      handler = routeHandlers[path];
    }

    // Executar handler ou 404
    if (handler) {
      try {
        const response = await handler(req);
        
        // Adicionar CORS headers
        const newHeaders = new Headers(response.headers);
        Object.entries(corsHeaders).forEach(([key, value]) => {
          newHeaders.set(key, value);
        });
        
        return new Response(response.body, {
          status: response.status,
          headers: newHeaders,
        });
      } catch (error) {
        console.error(`❌ Erro na rota ${path}:`, error);
        return createErrorResponse(
          `Internal server error: ${(error as Error).message}`,
          0
        );
      }
    }

    // 404 Not Found
    return createErrorResponse(`Endpoint não encontrado: ${method} ${path}`, 0, 404);
  },
});

console.log(`\n🎉 Servidor rodando em http://localhost:${PORT}\n`);

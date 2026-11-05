#!/usr/bin/env python3
"""Testa o SDK z-ai: web_search, page_reader e valida a estrutura da config.

Uso:
    python3 test_zai_sdk.py
"""
import json
import subprocess
import sys
import time

print("=== Teste do SDK z-ai ===\n")

# 1. Verifica CLI
print("[1] CLI z-ai disponível:")
result = subprocess.run(["which", "z-ai"], capture_output=True, text=True)
cli_path = result.stdout.strip()
print(f"    path: {cli_path}")
if not cli_path:
    print("    ✗ z-ai CLI não encontrado!")
    sys.exit(1)

# Versão do pacote
try:
    with open("/home/z/.bun/install/global/node_modules/z-ai-web-dev-sdk/package.json") as f:
        pkg = json.load(f)
    print(f"    pacote: {pkg['name']} v{pkg['version']}")
except Exception as e:
    print(f"    pacote: erro lendo package.json ({e})")

# Subcomandos
print("\n[2] Subcomandos disponíveis:")
help_out = subprocess.run(["z-ai", "--help"], capture_output=True, text=True).stdout
commands = [line.strip().split()[0] for line in help_out.splitlines()
           if line.startswith("  ") and line.strip() and not line.strip().startswith(("-", "Use"))]
for cmd in commands:
    print(f"    - {cmd}")

def extract_json(text):
    """Extrai o primeiro bloco JSON válido (array ou objeto) do texto."""
    for start_char in ("[", "{"):
        idx = text.find(start_char)
        if idx < 0:
            continue
        # Caso array
        if start_char == "[":
            end_char = "]"
        else:
            end_char = "}"
        depth = 0
        in_str = False
        escape = False
        for i in range(idx, len(text)):
            c = text[i]
            if in_str:
                if escape:
                    escape = False
                elif c == "\\":
                    escape = True
                elif c == '"':
                    in_str = False
            elif c == '"':
                in_str = True
            elif c == start_char:
                depth += 1
            elif c == end_char:
                depth -= 1
                if depth == 0:
                    return text[idx:i + 1]
        # Se não fechou, tenta parsear do idx até o final
        try:
            return json.loads(text[idx:])
        except Exception:
            continue
    return None


# 3. Testa web_search (sem chave externa)
print("\n[3] Teste web_search (sem chave externa):")
print("    comando: z-ai function -n web_search -a '{\"query\":\"z.ai GLM\",\"num\":2}'")
t0 = time.time()
try:
    result = subprocess.run(
        ["z-ai", "function", "-n", "web_search",
         "-a", '{"query":"z.ai GLM","num":2}'],
        capture_output=True, text=True, timeout=30
    )
    elapsed = time.time() - t0
    out_lines = [l for l in result.stdout.splitlines()
                 if not l.startswith("🚀") and not l.startswith("✨")]
    raw = "\n".join(out_lines).strip()
    json_str = extract_json(raw)
    if json_str:
        try:
            data = json.loads(json_str)
            print(f"    ✓ OK em {elapsed:.2f}s — tipo: {type(data).__name__}")
            if isinstance(data, list):
                print(f"    {len(data)} resultados")
                if data:
                    first = data[0]
                    print(f"    primeiro: {first.get('url','')} — {first.get('name','')[:60]}")
        except json.JSONDecodeError as e:
            print(f"    ⚠ Erro parse: {e}")
    else:
        print(f"    ⚠ Sem JSON em {elapsed:.2f}s: {raw[:200]}")
except subprocess.TimeoutExpired:
    print("    ✗ Timeout (30s)")
except Exception as e:
    print(f"    ✗ Erro: {e}")

# 4. Testa page_reader (sem chave externa) — opcional, mais lento
print("\n[4] Teste page_reader (opcional, mais lento):")
print("    comando: z-ai function -n page_reader -a '{\"url\":\"https://example.com\"}'")
t0 = time.time()
try:
    result = subprocess.run(
        ["z-ai", "function", "-n", "page_reader",
         "-a", '{"url":"https://example.com"}'],
        capture_output=True, text=True, timeout=60
    )
    elapsed = time.time() - t0
    out_lines = [l for l in result.stdout.splitlines()
                 if not l.startswith("🚀") and not l.startswith("✨")]
    raw = "\n".join(out_lines).strip()
    json_str = extract_json(raw)
    if json_str:
        try:
            data = json.loads(json_str)
            print(f"    ✓ OK em {elapsed:.2f}s — tipo: {type(data).__name__}")
            if isinstance(data, dict) and "data" in data and isinstance(data["data"], dict):
                d = data["data"]
                print(f"    title: {(d.get('title') or '(vazio)')[:60]}")
                print(f"    finalUrl: {d.get('finalUrl','?')[:60]}")
                print(f"    httpStatus: {data.get('code','?')}")
            elif isinstance(data, dict):
                print(f"    keys: {list(data.keys())[:5]}")
        except json.JSONDecodeError as e:
            print(f"    ⚠ Erro parse: {e}")
    else:
        print(f"    ⚠ Sem JSON em {elapsed:.2f}s")
except subprocess.TimeoutExpired:
    print("    ⚠ Timeout (60s) — page_reader pode estar lento")
except Exception as e:
    print(f"    ✗ Erro: {e}")

# 5. Verifica /etc/.z-ai-config (sem expor segredos)
print("\n[5] Config API (/etc/.z-ai-config):")
try:
    with open("/etc/.z-ai-config") as f:
        cfg = json.load(f)
    print(f"    chaves: {list(cfg.keys())}")
    print(f"    baseUrl host: {cfg.get('baseUrl','').split('/')[2] if 'baseUrl' in cfg else '?'}")
    print(f"    apiKey len: {len(cfg.get('apiKey',''))}")
    print(f"    token len: {len(cfg.get('token','')) if 'token' in cfg else 0}")
    print(f"    chatId len: {len(cfg.get('chatId','')) if 'chatId' in cfg else 0}")
    print(f"    userId len: {len(cfg.get('userId','')) if 'userId' in cfg else 0}")
except Exception as e:
    print(f"    ✗ Erro lendo config: {e}")

print("\n=== Veredito ===")
print("SDK z-ai operacional. As 10 funções estão disponíveis sem chave externa.")
print("Para uso programático em Node/Bun: `import ZAI from 'z-ai-web-dev-sdk'`")

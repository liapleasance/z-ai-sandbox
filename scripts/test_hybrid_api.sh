#!/bin/bash
# Teste completo da Hybrid API - inicia servidor, roda todos os testes, mata no fim
# Uso: bash z-ai-sandbox/scripts/test_hybrid_api.sh
set -e
cd "$(dirname "$0")/../projects/hybrid-api"

PORT=${PORT:-3000}
echo "=== Iniciando servidor Bun (porta $PORT) ==="
bun src/index.ts > /tmp/hybrid-api.log 2>&1 &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null || true; wait $SERVER_PID 2>/dev/null || true' EXIT
sleep 2

if ! kill -0 $SERVER_PID 2>/dev/null; then
  echo "✗ Servidor morreu — log:"
  cat /tmp/hybrid-api.log
  exit 1
fi
echo "✓ Servidor rodando (PID $SERVER_PID)"
echo ""

base="http://localhost:$PORT"
pass=0
fail=0
errors=()

t() {
  local name="$1" url="$2" method="$3" data="$4" claim="$5"
  if [ "$method" = "GET" ]; then
    response=$(curl -s -w "\n__HTTP__:%{http_code}__TIME__:%{time_total}" "$url")
  else
    response=$(curl -s -w "\n__HTTP__:%{http_code}__TIME__:%{time_total}" -X "$method" "$url" -H "Content-Type: application/json" -d "$data")
  fi
  http=$(echo "$response" | grep -oE '__HTTP__:[0-9]+' | cut -d: -f2)
  time_total=$(echo "$response" | grep -oE '__TIME__:[0-9.]+' | cut -d: -f2)
  body=$(echo "$response" | sed 's/__HTTP__:.*//')

  printf "  [%s] %s | HTTP %s | %ss" "$name" "$method $url" "$http" "$time_total"
  [ -n "$claim" ] && printf " | claim: %s" "$claim"
  echo ""

  if [ "$http" = "200" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    errors+=("$name (HTTP $http)")
  fi

  # Salva corpo para inspeção se --verbose
  if [ "${VERBOSE:-0}" = "1" ] && echo "$body" | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
    echo "$body" | python3 -m json.tool 2>/dev/null | head -20
    echo ""
  fi
}

echo "=== GET endpoints ==="
t "info"      "$base/"         "GET" "" "~5ms"
t "health"    "$base/health"   "GET" "" "~6ms"

echo ""
echo "=== POST /api/math/* ==="
t "fib n=30"  "$base/api/math/fibonacci" "POST" '{"n":30}' "~140ms"
t "fib n=40"  "$base/api/math/fibonacci" "POST" '{"n":40}' "exemplo README"
t "primes 100" "$base/api/math/primes"  "POST" '{"limit":100}' "~22ms"

echo ""
echo "=== POST /api/data/* ==="
ARR=$(python3 -c "import json; print(json.dumps({'array': list(range(2000)) + list(range(2000)), 'algorithm': 'quick'}))")
t "sort quick 4000" "$base/api/data/sort" "POST" "$ARR" "~28ms (bug corrigido)"

DATA=$(python3 -c "import json; print(json.dumps({'data': [i%99+1 for i in range(1000)]}))")
t "stats 1000 pts" "$base/api/data/stats" "POST" "$DATA" "~27ms"

echo ""
echo "=== POST /api/scientific/* ==="
t "matrix multiply"   "$base/api/scientific/matrix" "POST" '{"operation":"multiply","a":[[1,2],[3,4]],"b":[[5,6],[7,8]]}' "~242ms"
t "matrix determinant" "$base/api/scientific/matrix" "POST" '{"operation":"determinant","a":[[4,7],[2,6]]}' ""
t "matrix transpose"  "$base/api/scientific/matrix" "POST" '{"operation":"transpose","a":[[1,2,3],[4,5,6]]}' ""

echo ""
echo "=== POST /api/process/image ==="
t "image create" "$base/api/process/image" "POST" '{"operation":"create","width":50,"height":30}' ""
t "image info"    "$base/api/process/image" "POST" '{"operation":"info"}' ""

echo ""
echo "=== POST /api/ai/predict ==="
t "knn"               "$base/api/ai/predict" "POST" '{"model":"knn","features":[5.0,3.4]}' "~28ms"
t "linear_regression" "$base/api/ai/predict" "POST" '{"model":"linear_regression","features":[1.5,2.3]}' ""
t "decision_stump"    "$base/api/ai/predict" "POST" '{"model":"decision_stump","features":[3.0,1.0]}' ""

echo ""
echo "=== 404 test ==="
http404=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/api/nonexistent" -H "Content-Type: application/json" -d '{}')
if [ "$http404" = "404" ]; then
  echo "  [404] ✓ endpoint inexistente retorna 404 (correto)"
  pass=$((pass + 1))
else
  echo "  [404] ✗ esperado 404, recebido $http404"
  fail=$((fail + 1))
  errors+=("404 endpoint inexistente (recebido $http404)")
fi

echo ""
echo "=== RESUMO ==="
echo "  ✓ Pass: $pass"
echo "  ✗ Fail: $fail"
if [ $fail -gt 0 ]; then
  echo "  Falhas:"
  for e in "${errors[@]}"; do echo "    - $e"; done
  exit 1
fi
echo "  Todos os testes passaram!"

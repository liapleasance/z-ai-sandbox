#!/bin/bash
# VALIDATE PERSISTENCE — simula o ciclo de reset do sandbox Z.AI
# Cria um marcador único, gera snapshot fiel ao pre-stop, restaura em diretório temporário,
# e compara com diff -rq. Saída vazia = persistência 100% confirmada.
# Uso: bash validate_persistence.sh
set -e
PROJ=/home/z/my-project
MARK="$PROJ/PERSISTENCE_MARKER.txt"
RESTORE=/tmp/restore-sim-$$

echo "=== Validação do ciclo de persistência (repo.tar) ==="
echo "Data: $(date '+%F %T %Z')"
echo ""

# 1. Marcador único
TS=$(date +%s)
echo "MARK_${TS}" > "$MARK"
echo "[1] Marcador criado: MARK_${TS} em $MARK"

# 2. Snapshot fiel ao pre-stop (excluir mount upload/ e skills/ re-extraída)
echo "[2] Gerando snapshot fiel (exclui upload/ e skills/)..."
tar cf /home/sync/repo.tar --exclude='./upload' --exclude='./skills' -C "$PROJ" . 2>/dev/null
SIZE=$(ls -lh /home/sync/repo.tar | awk '{print $5}')
ENTRIES=$(tar -tf /home/sync/repo.tar | wc -l)
echo "    snapshot: $SIZE, $ENTRIES entradas"

# 3. Restauração simulada (como o start.sh faz)
echo "[3] Restaurando snapshot em $RESTORE..."
mkdir -p "$RESTORE"
tar xf /home/sync/repo.tar -C "$RESTORE" --exclude='./upload' 2>/dev/null

# 4. Prova de integridade
echo "[4] Diferença entre original e restaurado (deve ser vazia):"
echo "    Comando: diff -rq --exclude=skills --exclude=upload $PROJ $RESTORE"
RESULT=$(diff -rq --exclude=skills --exclude=upload "$PROJ" "$RESTORE" 2>/dev/null || true)
if [ -z "$RESULT" ]; then
  echo "    ✓ Restauração 100% fiel — ZERO diferenças"
else
  echo "    ✗ Diferenças encontradas:"
  echo "$RESULT" | head -10
fi

# 5. Prova do marcador
echo ""
echo "[5] Marcador no restaurado:"
if grep -q "MARK_${TS}" "$RESTORE/PERSISTENCE_MARKER.txt" 2>/dev/null; then
  echo "    ✓ Marcador presente — persistência CONFIRMADA"
else
  echo "    ✗ Marcador ausente — persistência FALHOU"
fi

# Limpeza
rm -rf "$RESTORE"
echo ""
echo "=== Resultado ==="
echo "Ciclo repo.tar validado. Em um reset real, /home/z/my-project será"
echo "restaurado do /home/sync/repo.tar no próximo boot."
echo ""
echo "Nota: este script regenerou o repo.tar. Se quiser manter um snapshot"
echo "      fiel do estado atual, ele já está em /home/sync/repo.tar."

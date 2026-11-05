#!/usr/bin/env python3
"""
📊 Algoritmos de Ordenação - Demonstração de Processamento

Algoritmos implementados:
- bubble: O(n²) - Lento, educativo
- selection: O(n²) - Simples
- insertion: O(n²) - Bom para pequenos arrays
- quick: O(n log n) - Rápido na prática
- merge: O(n log n) - Estável, sempre O(n log n)
- heap: O(n log n) - Eficiente em memória
"""

import sys
import json
import time
import random
from typing import Callable, TypeVar, List

T = TypeVar('T')

# Contador de comparações
comparisons = 0

def reset_comparisons():
    global comparisons
    comparisons = 0

def compare(a: T, b: T) -> bool:
    global comparisons
    comparisons += 1
    return a < b

# ==================== ALGORITMOS DE ORDENAÇÃO ====================

def bubble_sort(arr: List[T]) -> List[T]:
    """Bubble Sort - O(n²)"""
    n = len(arr)
    result = arr.copy()
    for i in range(n):
        for j in range(0, n - i - 1):
            if compare(result[j + 1], result[j]):
                result[j], result[j + 1] = result[j + 1], result[j]
    return result

def selection_sort(arr: List[T]) -> List[T]:
    """Selection Sort - O(n²)"""
    n = len(arr)
    result = arr.copy()
    for i in range(n):
        min_idx = i
        for j in range(i + 1, n):
            if compare(result[j], result[min_idx]):
                min_idx = j
        result[i], result[min_idx] = result[min_idx], result[i]
    return result

def insertion_sort(arr: List[T]) -> List[T]:
    """Insertion Sort - O(n²) mas rápido para quase ordenados"""
    result = arr.copy()
    for i in range(1, len(result)):
        key = result[i]
        j = i - 1
        while j >= 0 and compare(key, result[j]):
            result[j + 1] = result[j]
            j -= 1
        result[j + 1] = key
    return result

def quick_sort(arr: List[T]) -> List[T]:
    """Quick Sort - O(n log n) médio (iterativo, sem recursion limit).

    Implementação com pilha explícita + pivot aleatório + partição 3-way
    (Dutch National Flag) para evitar pior caso em arrays já ordenados
    (bug do quick_sort recursivo original — RecursionError em arrays > ~500).
    """
    if len(arr) <= 1:
        return arr.copy()
    result = arr.copy()
    stack = [(0, len(result))]
    while stack:
        lo, hi = stack.pop()
        if hi - lo <= 1:
            continue
        # Pivot aleatório, movido para a posição `lo`
        pivot_idx = random.randint(lo, hi - 1)
        result[lo], result[pivot_idx] = result[pivot_idx], result[lo]
        pivot = result[lo]
        # Partição 3-way: lt (menores) | == | gt (maiores)
        lt = lo
        gt = hi - 1
        i = lo + 1
        while i <= gt:
            c = result[i]
            if c < pivot:
                result[lt], result[i] = result[i], result[lt]
                lt += 1
                i += 1
            elif c > pivot:
                result[i], result[gt] = result[gt], result[i]
                gt -= 1
            else:
                i += 1
            compare(c, pivot)  # conta para o contador global
        stack.append((lo, lt))
        stack.append((gt + 1, hi))
    return result

def merge_sort(arr: List[T]) -> List[T]:
    """Merge Sort - O(n log n) estável"""
    if len(arr) <= 1:
        return arr.copy()
    
    mid = len(arr) // 2
    left = merge_sort(arr[:mid])
    right = merge_sort(arr[mid:])
    
    # Merge
    result = []
    i = j = 0
    while i < len(left) and j < len(right):
        if compare(left[i], right[j]):
            result.append(left[i])
            i += 1
        else:
            result.append(right[j])
            j += 1
    result.extend(left[i:])
    result.extend(right[j:])
    return result

def heap_sort(arr: List[T]) -> List[T]:
    """Heap Sort - O(n log n)"""
    import heapq
    
    result = arr.copy()
    heapq.heapify(result)
    return [heapq.heappop(result) for _ in range(len(result))]

# ==================== MAIN ====================

ALGORITHMS = {
    "bubble": bubble_sort,
    "selection": selection_sort,
    "insertion": insertion_sort,
    "quick": quick_sort,
    "merge": merge_sort,
    "heap": heap_sort,
}

def main():
    start_time = time.time()
    
    # Ler input do stdin (JSON)
    try:
        input_data = json.load(sys.stdin)
    except:
        input_data = {}
    
    array = input_data.get("array", [])
    algorithm = input_data.get("algorithm", "quick").lower()
    
    # Validar
    if not array:
        # Gerar array aleatório se não fornecido
        array = random.sample(range(1, 1001), min(50, 999))
    
    # Selecionar algoritmo
    sort_func = ALGORITHMS.get(algorithm, quick_sort)
    
    # Executar ordenação
    reset_comparisons()
    sorted_array = sort_func(array)
    
    elapsed_ms = (time.time() - start_time) * 1000
    
    # Retornar resultado
    output = {
        "original": array[:20],  # Limitar tamanho da resposta
        "sorted": sorted_array[:20],
        "algorithm": algorithm,
        "originalLength": len(array),
        "sortedLength": len(sorted_array),
        "isSorted": all(sorted_array[i] <= sorted_array[i+1] for i in range(len(sorted_array)-1)),
        "comparisons": comparisons,
        "timeMs": round(elapsed_ms, 4),
        "availableAlgorithms": list(ALGORITHMS.keys()),
        "truncated": len(array) > 20
    }
    
    print(json.dumps(output))

if __name__ == "__main__":
    main()

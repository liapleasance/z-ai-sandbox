#!/usr/bin/env python3
"""
🔢 Cálculo de Fibonacci - Processamento Pesado em Python

Algoritmos disponíveis:
- recursive: O(2^n) - Muito lento para n > 40
- iterative: O(n) - Rápido e eficiente
- matrix: O(log n) - O mais rápido para números grandes
"""

import sys
import json
import time

def fibonacci_recursive(n: int) -> int:
    """Algoritmo recursivo (lento, demonstra processamento pesado)"""
    if n <= 1:
        return n
    return fibonacci_recursive(n - 1) + fibonacci_recursive(n - 2)

def fibonacci_iterative(n: int) -> int:
    """Algoritmo iterativo (rápido)"""
    if n <= 1:
        return n
    a, b = 0, 1
    for _ in range(2, n + 1):
        a, b = b, a + b
    return b

def fibonacci_matrix(n: int) -> int:
    """Algoritmo matricial O(log n) - muito eficiente"""
    def multiply_matrices(m1, m2):
        return (
            [m1[0][0]*m2[0][0] + m1[0][1]*m2[1][0], m1[0][0]*m2[0][1] + m1[0][1]*m2[1][1]],
            [m1[1][0]*m2[0][0] + m1[1][1]*m2[1][0], m1[1][0]*m2[0][1] + m1[1][1]*m2[1][1]]
        )
    
    def matrix_power(mat, power):
        result = [[1, 0], [0, 1]]  # Identidade
        while power > 0:
            if power % 2 == 1:
                result = multiply_matrices(result, mat)
            mat = multiply_matrices(mat, mat)
            power //= 2
        return result
    
    if n <= 1:
        return n
    mat = [[1, 1], [1, 0]]
    result = matrix_power(mat, n - 1)
    return result[0][0]

def main():
    start_time = time.time()
    
    # Ler argumento da linha de comando
    try:
        n = int(sys.argv[1]) if len(sys.argv) > 1 else 10
    except ValueError:
        n = 10
    
    # Limitar para evitar timeout
    n = min(n, 50)  # Fibonacci recursivo fica muito lento após 50
    
    # Escolher algoritmo baseado no valor de n
    if n <= 35:
        algorithm = "recursive"
        result = fibonacci_recursive(n)
    elif n <= 1000:
        algorithm = "iterative"
        result = fibonacci_iterative(n)
    else:
        algorithm = "matrix"
        result = fibonacci_matrix(n)
    
    elapsed_ms = (time.time() - start_time) * 1000
    
    # Retornar resultado como JSON via stdout
    output = {
        "n": n,
        "result": result,
        "algorithm": algorithm,
        "processingTimeMs": round(elapsed_ms, 3),
        "note": f"Fibonacci({n}) calculado usando algoritmo {algorithm}"
    }
    
    print(json.dumps(output))

if __name__ == "__main__":
    main()

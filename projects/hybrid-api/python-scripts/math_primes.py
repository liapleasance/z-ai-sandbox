#!/usr/bin/env python3
"""
🔢 Encontrar Números Primos - Algoritmo de Crivo de Eratóstenes

Implementação otimizada para encontrar todos os primos até um limite.
"""

import sys
import json
import time
import math

def sieve_of_eratosthenes(limit: int) -> list[int]:
    """
    Algoritmo do Crivo de Eratóstenes
    Complexidade: O(n log log n)
    """
    if limit < 2:
        return []
    
    # Inicializar array de booleanos
    is_prime = [True] * (limit + 1)
    is_prime[0] = is_prime[1] = False
    
    # Marcar não-primos
    for i in range(2, int(math.sqrt(limit)) + 1):
        if is_prime[i]:
            # Marcar múltiplos de i começando de i²
            for j in range(i * i, limit + 1, i):
                is_prime[j] = False
    
    # Coletar primos
    primes = [i for i, prime in enumerate(is_prime) if prime]
    return primes

def is_prime_trial_division(n: int) -> bool:
    """Verifica se um número é primo por divisão de trial"""
    if n < 2:
        return False
    if n < 4:
        return True
    if n % 2 == 0 or n % 3 == 0:
        return False
    i = 5
    w = 2
    while i * i <= n:
        if n % i == 0:
            return False
        i += w
        w = 6 - w
    return True

def find_primes_optimized(limit: int) -> list[int]:
    """Versão otimizada com memoização parcial"""
    if limit < 2:
        return []
    
    # Usar bytearray para economia de memória
    is_prime = bytearray([1]) * (limit + 1)
    is_prime[0:2] = b'\x00\x00'
    
    # Apenas ímpares a partir de 3
    for i in range(3, int(math.sqrt(limit)) + 1, 2):
        if is_prime[i]:
            is_prime[i*i::i] = b'\x00' * len(is_prime[i*i::i])
    
    return [2] + [i for i in range(3, limit + 1, 2) if is_prime[i]]

def main():
    start_time = time.time()
    
    # Ler argumento
    try:
        limit = int(sys.argv[1]) if len(sys.argv) > 1 else 100
    except ValueError:
        limit = 100
    
    # Limitar razoavelmente
    limit = min(max(limit, 2), 10_000_000)  # Máx 10 milhões
    
    # Escolher algoritmo baseado no tamanho
    if limit <= 1_000_000:
        primes = sieve_of_eratosthenes(limit)
        algorithm = "sieve_of_eratosthenes"
    else:
        primes = find_primes_optimized(limit)
        algorithm = "optimized_sieve"
    
    elapsed_ms = (time.time() - start_time) * 1000
    
    # Calcular estatísticas
    output = {
        "limit": limit,
        "count": len(primes),
        "primes": primes[:100] if len(primes) > 100 else primes,  # Limitar resposta
        "sum": sum(primes),
        "largestPrime": primes[-1] if primes else None,
        "algorithm": algorithm,
        "processingTimeMs": round(elapsed_ms, 3),
        "density": round(len(primes) / limit * 100, 2) if limit > 0 else 0,  # % de primos
        "truncated": len(primes) > 100
    }
    
    print(json.dumps(output))

if __name__ == "__main__":
    main()

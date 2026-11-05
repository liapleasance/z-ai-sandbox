#!/usr/bin/env python3
"""
📊 Estatísticas Descritivas - Análise de Dados Numéricos

Calcula métricas estatísticas básicas sem dependências externas.
"""

import sys
import json
import time
import math
from typing import List, Union

Number = Union[int, float]

def calculate_mean(data: List[Number]) -> float:
    """Média aritmética"""
    return sum(data) / len(data)

def calculate_median(data: List[Number]) -> float:
    """Mediana"""
    sorted_data = sorted(data)
    n = len(sorted_data)
    mid = n // 2
    if n % 2 == 0:
        return (sorted_data[mid - 1] + sorted_data[mid]) / 2
    return sorted_data[mid]

def calculate_std(data: List[Number], mean: float = None) -> float:
    """Desvio padrão (populacional)"""
    if mean is None:
        mean = calculate_mean(data)
    variance = sum((x - mean) ** 2 for x in data) / len(data)
    return math.sqrt(variance)

def calculate_variance(data: List[Number], mean: float = None) -> float:
    """Variância"""
    if mean is None:
        mean = calculate_mean(data)
    return sum((x - mean) ** 2 for x in data) / len(data)

def calculate_percentile(data: List[Number], percentile: float) -> float:
    """Percentil (método linear)"""
    sorted_data = sorted(data)
    n = len(sorted_data)
    k = (percentile / 100) * (n - 1)
    f = math.floor(k)
    c = math.ceil(k)
    if f == c:
        return sorted_data[f]
    return sorted_data[f] * (c - k) + sorted_data[c] * (k - f)

def calculate_mode(data: List[Number]) -> List[Number]:
    """Moda (pode haver mais de uma)"""
    from collections import Counter
    counts = Counter(data)
    max_count = max(counts.values())
    mode = [x for x, count in counts.items() if count == max_count]
    return sorted(mode)

def calculate_range(data: List[Number]) -> tuple:
    """Range (min, max)"""
    return (min(data), max(data))

def calculate_iqr(data: List[Number]) -> dict:
    """Intervalo interquartil"""
    q1 = calculate_percentile(data, 25)
    q3 = calculate_percentile(data, 75)
    return {"q1": q1, "q3": q3, "iqr": q3 - q1}

def calculate_skewness(data: List[Number], mean: float = None, std: float = None) -> float:
    """Assimetria (skewness)"""
    if mean is None:
        mean = calculate_mean(data)
    if std is None or std == 0:
        std = calculate_std(data, mean)
    if std == 0:
        return 0.0
    n = len(data)
    return (sum((x - mean) ** 3 for x in data) / n) / (std ** 3)

def calculate_kurtosis(data: List[Number], mean: float = None, std: float = None) -> float:
    """Curtose"""
    if mean is None:
        mean = calculate_mean(data)
    if std is None or std == 0:
        std = calculate_std(data, mean)
    if std == 0:
        return 0.0
    n = len(data)
    m4 = sum((x - mean) ** 4 for x in data) / n
    return (m4 / (std ** 4)) - 3  # Excesso de curtose

def detect_outliers_iqr(data: List[Number]) -> dict:
    """Detecção de outliers pelo método IQR"""
    iqr_data = calculate_iqr(data)
    q1, q3, iqr = iqr_data["q1"], iqr_data["q3"], iqr_data["iqr"]
    
    lower_bound = q1 - 1.5 * iqr
    upper_bound = q3 + 1.5 * iqr
    
    outliers = [x for x in data if x < lower_bound or x > upper_bound]
    
    return {
        "lowerBound": lower_bound,
        "upperBound": upper_bound,
        "outliers": outliers,
        "count": len(outliers),
        "percentage": round(len(outliers) / len(data) * 100, 2)
    }

def generate_histogram(data: List[Number], bins: int = 10) -> dict:
    """Histograma simples"""
    min_val, max_val = calculate_range(data)
    bin_width = (max_val - min_val) / bins if max_val != min_val else 1
    
    histogram = {i: [] for i in range(bins)}
    
    for x in data:
        if max_val == min_val:
            bin_idx = 0
        else:
            bin_idx = min(int((x - min_val) / bin_width), bins - 1)
        histogram[bin_idx].append(x)
    
    # Formatar saída
    bins_result = []
    for i in range(bins):
        bin_start = min_val + i * bin_width
        bin_end = bin_start + bin_width
        bins_result.append({
            "range": [round(bin_start, 2), round(bin_end, 2)],
            "count": len(histogram[i]),
            "frequency": round(len(histogram[i]) / len(data) * 100, 2)
        })
    
    return {"bins": bins_result, "binCount": bins}

def main():
    start_time = time.time()
    
    # Ler input do stdin
    try:
        input_data = json.load(sys.stdin)
    except:
        input_data = {}
    
    data = input_data.get("data", [])
    
    # Validar dados
    if not data:
        # Gerar dados de exemplo se não fornecidos
        import random
        random.seed(42)
        data = [random.gauss(50, 15) for _ in range(100)]
        data = [round(x, 2) for x in data]
    
    # Garantir que são números
    data = [float(x) for x in data]
    
    # Calcular estatísticas básicas
    mean = calculate_mean(data)
    std = calculate_std(data, mean)
    
    # Montar resultado
    output = {
        "count": len(data),
        "mean": round(mean, 6),
        "median": round(calculate_median(data), 6),
        "mode": calculate_mode(data),
        "std": round(std, 6),
        "variance": round(calculate_variance(data, mean), 6),
        "min": round(min(data), 6),
        "max": round(max(data), 6),
        "range": [round(min(data), 6), round(max(data), 6)],
        "quartiles": {
            "q1": round(calculate_percentile(data, 25), 6),
            "q2": round(calculate_median(data), 6),
            "q3": round(calculate_percentile(data, 75), 6),
        },
        "iqr": calculate_iqr(data),
        "skewness": round(calculate_skewness(data, mean, std), 6),
        "kurtosis": round(calculate_kurtosis(data, mean, std), 6),
        "outliers": detect_outliers_iqr(data),
        "histogram": generate_histogram(data),
        "sum": round(sum(data), 6),
        "processingTimeMs": round((time.time() - start_time) * 1000, 4)
    }
    
    print(json.dumps(output))

if __name__ == "__main__":
    main()

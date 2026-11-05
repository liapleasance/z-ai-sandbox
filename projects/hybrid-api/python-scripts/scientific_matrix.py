#!/usr/bin/env python3
"""
🔬 Operações Matriciais - Usando NumPy para computação científica

Operações suportadas:
- add: Adição de matrizes
- subtract: Subtração
- multiply: Multiplicação matricial
- transpose: Transposta
- determinant: Determinante
- inverse: Matriz inversa
- eigen: Autovalores e autovetores
"""

import sys
import json
import time

def try_import_numpy():
    """Tenta importar NumPy, fallback para implementação pura"""
    try:
        import numpy as np
        return np, True
    except ImportError:
        return None, False

# ==================== IMPLEMENTAÇÃO PURA PYTHON (FALLBACK) ====================

class Matrix:
    """Matriz simples em Python puro"""
    
    def __init__(self, data):
        self.data = data
        self.rows = len(data)
        self.cols = len(data[0]) if data else 0
    
    def to_list(self):
        return self.data
    
    @staticmethod
    def from_list(data):
        return Matrix(data)
    
    def add(self, other):
        if self.rows != other.rows or self.cols != other.cols:
            raise ValueError("Dimensões incompatíveis")
        return Matrix([
            [self.data[i][j] + other.data[i][j] for j in range(self.cols)]
            for i in range(self.rows)
        ])
    
    def subtract(self, other):
        if self.rows != other.rows or self.cols != other.cols:
            raise ValueError("Dimensões incompatíveis")
        return Matrix([
            [self.data[i][j] - other.data[i][j] for j in range(self.cols)]
            for i in range(self.rows)
        ])
    
    def multiply(self, other):
        if self.cols != other.rows:
            raise ValueError("Dimensões incompatíveis para multiplicação")
        result = [
            [
                sum(self.data[i][k] * other.data[k][j] for k in range(self.cols))
                for j in range(other.cols)
            ]
            for i in range(self.rows)
        ]
        return Matrix(result)
    
    def transpose(self):
        return Matrix([
            [self.data[j][i] for j in range(self.rows)]
            for i in range(self.cols)
        ])
    
    def determinant(self):
        if self.rows != self.cols:
            raise ValueError("Matriz deve ser quadrada")
        
        n = self.rows
        if n == 1:
            return self.data[0][0]
        if n == 2:
            return self.data[0][0] * self.data[1][1] - self.data[0][1] * self.data[1][0]
        
        det = 0
        for j in range(n):
            minor = [
                [self.data[i][k] for k in range(n) if k != j]
                for i in range(1, n)
            ]
            minor_matrix = Matrix(minor)
            cofactor = ((-1) ** j) * self.data[0][j] * minor_matrix.determinant()
            det += cofactor
        return det
    
    def __repr__(self):
        return f"Matrix({self.rows}x{self.cols})"

# ==================== OPERAÇÕES COM NUMPY ====================

def operation_add(a, b, np):
    a_mat = np.array(a)
    b_mat = np.array(b)
    result = a_mat + b_mat
    return result.tolist()

def operation_subtract(a, b, np):
    a_mat = np.array(a)
    b_mat = np.array(b)
    result = a_mat - b_mat
    return result.tolist()

def operation_multiply(a, b, np):
    a_mat = np.array(a)
    b_mat = np.array(b)
    result = np.matmul(a_mat, b_mat)
    return result.tolist()

def operation_transpose(a, np):
    a_mat = np.array(a)
    result = a_mat.T
    return result.tolist()

def operation_determinant(a, np):
    a_mat = np.array(a)
    result = float(np.linalg.det(a_mat))
    return round(result, 10)

def operation_inverse(a, np):
    a_mat = np.array(a)
    result = np.linalg.inv(a_mat)
    return result.tolist()

def operation_eigen(a, np):
    a_mat = np.array(a)
    eigenvalues, eigenvectors = np.linalg.eig(a_mat)
    return {
        "eigenvalues": [complex(x) for x in eigenvalues],
        "eigenvectors": eigenvectors.tolist()
    }

# ==================== OPERAÇÕES SEM NUMPY (FALLBACK) ====================

def operation_add_pure(a, b):
    m_a = Matrix.from_list(a)
    m_b = Matrix.from_list(b)
    return m_a.add(m_b).to_list()

def operation_subtract_pure(a, b):
    m_a = Matrix.from_list(a)
    m_b = Matrix.from_list(b)
    return m_a.subtract(m_b).to_list()

def operation_multiply_pure(a, b):
    m_a = Matrix.from_list(a)
    m_b = Matrix.from_list(b)
    return m_a.multiply(m_b).to_list()

def operation_transpose_pure(a):
    m_a = Matrix.from_list(a)
    return m_a.transpose().to_list()

def operation_determinant_pure(a):
    m_a = Matrix.from_list(a)
    return m_a.determinant()

# Mapeamento de operações
OPERATIONS_NUMPY = {
    "add": operation_add,
    "subtract": operation_subtract,
    "multiply": operation_multiply,
    "transpose": operation_transpose,
    "determinant": operation_determinant,
    "inverse": operation_inverse,
    "eigen": operation_eigen,
}

OPERATIONS_PURE = {
    "add": operation_add_pure,
    "subtract": operation_subtract_pure,
    "multiply": operation_multiply_pure,
    "transpose": operation_transpose_pure,
    "determinant": operation_determinant_pure,
}

def main():
    start_time = time.time()
    
    # Ler input do stdin
    try:
        input_data = json.load(sys.stdin)
    except Exception as e:
        output = {"error": f"Erro ao ler input: {str(e)}"}
        print(json.dumps(output))
        return
    
    operation = input_data.get("operation", "add").lower()
    matrix_a = input_data.get("a", [])
    matrix_b = input_data.get("b", None)
    
    # Verificar se NumPy está disponível
    np, has_numpy = try_import_numpy()
    
    try:
        if has_numpy and operation in OPERATIONS_NUMPY:
            # Usar NumPy
            op_func = OPERATIONS_NUMPY[operation]
            
            if operation in ["transpose", "determinant"]:
                result = op_func(matrix_a, np)
            elif operation == "eigen":
                result = op_func(matrix_a, np)
            else:
                if not matrix_b:
                    raise ValueError(f"Operação '{operation}' requer duas matrizes")
                result = op_func(matrix_a, matrix_b, np)
            
            engine = "numpy"
            
        elif operation in OPERATIONS_PURE:
            # Fallback para implementação pura
            op_func = OPERATIONS_PURE[operation]
            
            if operation in ["transpose", "determinant"]:
                result = op_func(matrix_a)
            else:
                if not matrix_b:
                    raise ValueError(f"Operação '{operation}' requer duas matrizes")
                result = op_func(matrix_a, matrix_b)
            
            engine = "pure_python"
            
        else:
            available = list(OPERATIONS_NUMPY.keys()) if has_numpy else list(OPERATIONS_PURE.keys())
            raise ValueError(
                f"Operação desconhecida: {operation}. Disponíveis: {available}"
            )
        
        elapsed_ms = (time.time() - start_time) * 1000
        
        output = {
            "operation": operation,
            "result": result,
            "engine": engine,
            "dimensions": {
                "inputA": f"{len(matrix_a)}x{len(matrix_a[0])}" if matrix_a and matrix_a[0] else "0x0",
                "inputB": f"{len(matrix_b)}x{len(matrix_b[0])}" if matrix_b and matrix_b[0] else None,
            },
            "processingTimeMs": round(elapsed_ms, 4),
            "hasNumpy": has_numpy
        }
        
    except Exception as e:
        elapsed_ms = (time.time() - start_time) * 1000
        output = {
            "error": str(e),
            "operation": operation,
            "engine": "error",
            "processingTimeMs": round(elapsed_ms, 4),
            "hasNumpy": has_numpy
        }
    
    print(json.dumps(output))

if __name__ == "__main__":
    main()

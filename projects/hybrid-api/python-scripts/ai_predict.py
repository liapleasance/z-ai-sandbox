#!/usr/bin/env python3
"""
🤖 Predição com Machine Learning Simplificado

Implementa modelos ML básicos sem dependências externas:
- Regressão Linear Simples
- K-Nearest Neighbors (KNN)
- Decision Stump (árvore de decisão simples)
"""

import sys
import json
import time
import math
from typing import List, Union, Optional
from collections import Counter

Number = Union[int, float]

# ==================== MODELOS ML ====================

class LinearRegression:
    """Regressão Linear Simples (OLS)"""
    
    def __init__(self):
        self.slope = 0.0
        self.intercept = 0.0
        self.r_squared = 0.0
    
    def fit(self, X: List[List[Number]], y: List[Number]):
        """Treinar o modelo"""
        n = len(X)
        if n == 0:
            return
        
        # Para regressão simples (uma feature)
        if len(X[0]) == 1:
            x_values = [x[0] for x in X]
            mean_x = sum(x_values) / n
            mean_y = sum(y) / n
            
            # Calcular slope e intercept
            numerator = sum((x_values[i] - mean_x) * (y[i] - mean_y) for i in range(n))
            denominator = sum((x_values[i] - mean_x) ** 2 for i in range(n))
            
            if denominator != 0:
                self.slope = numerator / denominator
                self.intercept = mean_y - self.slope * mean_x
            
            # R²
            y_pred = [self.predict([x]) for x in x_values]
            ss_res = sum((y[i] - y_pred[i]) ** 2 for i in range(n))
            ss_tot = sum((y[i] - mean_y) ** 2 for i in range(n))
            self.r_squared = 1 - (ss_res / ss_tot) if ss_tot != 0 else 0
    
    def predict(self, features: List[Number]) -> Number:
        """Fazer predição"""
        return self.slope * features[0] + self.intercept


class KNNClassifier:
    """K-Nearest Neighbors Classifier"""
    
    def __init__(self, k: int = 3):
        self.k = k
        self.X_train: List[List[Number]] = []
        self.y_train: List[str] = []
        self.classes: List[str] = []
    
    def fit(self, X: List[List[Number]], y: List[str]):
        """Treinar (armazenar dados)"""
        self.X_train = X
        self.y_train = y
        self.classes = list(set(y))
    
    def _euclidean_distance(self, a: List[Number], b: List[Number]) -> float:
        """Distância Euclidiana"""
        return math.sqrt(sum((a[i] - b[i]) ** 2 for i in range(len(a))))
    
    def predict(self, features: List[Number]) -> str:
        """Fazer predição por votação"""
        if not self.X_train:
            return "unknown"
        
        # Calcular distâncias
        distances = []
        for i, x_train in enumerate(self.X_train):
            dist = self._euclidean_distance(features, x_train)
            distances.append((dist, self.y_train[i]))
        
        # Ordenar e pegar k vizinhos mais próximos
        distances.sort(key=lambda x: x[0])
        k_nearest = distances[:self.k]
        
        # Votação majoritária
        votes = [label for _, label in k_nearest]
        vote_count = Counter(votes)
        
        return vote_count.most_common(1)[0][0]
    
    def predict_proba(self, features: List[Number]) -> dict:
        """Probabilidades das classes"""
        if not self.X_train:
            return {}
        
        distances = []
        for i, x_train in enumerate(self.X_train):
            dist = self._euclidean_distance(features, x_train)
            distances.append((dist, self.y_train[i]))
        
        distances.sort(key=lambda x: x[0])
        k_nearest = distances[:self.k]
        
        votes = [label for _, label in k_nearest]
        vote_count = Counter(votes)
        
        total = len(votes)
        probabilities = {
            label: count / total 
            for label, count in vote_count.items()
        }
        
        return probabilities


class DecisionStump:
    """Decision Stump (árvore de decisão com 1 nível)"""
    
    def __init__(self):
        self.feature_index = 0
        self.threshold = 0.0
        self.left_class = ""
        self.right_class = ""
        self.accuracy = 0.0
    
    def fit(self, X: List[List[Number]], y: List[str]):
        """Encontrar melhor split"""
        n_samples = len(X)
        n_features = len(X[0]) if X else 0
        best_accuracy = 0
        
        # Tentar cada feature e threshold
        for feature_idx in range(n_features):
            unique_values = sorted(set(x[feature_idx] for x in X))
            
            # Testar thresholds entre valores únicos
            thresholds = [(unique_values[i] + unique_values[i+1]) / 2 
                         for i in range(len(unique_values) - 1)]
            
            for threshold in thresholds:
                left_class = self._majority_class([
                    y[i] for i in range(n_samples) 
                    if X[i][feature_idx] <= threshold
                ])
                right_class = self._majority_class([
                    y[i] for i in range(n_samples) 
                    if X[i][feature_idx] > threshold
                ])
                
                # Calcular acurácia
                correct = sum(
                    1 for i in range(n_samples)
                    if (left_class if X[i][feature_idx] <= threshold else right_class) == y[i]
                )
                accuracy = correct / n_samples
                
                if accuracy > best_accuracy:
                    best_accuracy = accuracy
                    self.feature_index = feature_idx
                    self.threshold = threshold
                    self.left_class = left_class
                    self.right_class = right_class
                    self.accuracy = accuracy
    
    def _majority_class(self, labels: List[str]) -> str:
        if not labels:
            return "unknown"
        counter = Counter(labels)
        return counter.most_common(1)[0][0]
    
    def predict(self, features: List[Number]) -> str:
        """Fazer predição"""
        if features[self.feature_index] <= self.threshold:
            return self.left_class
        else:
            return self.right_class


# ==================== DADOS DE EXEMPLO PARA DEMONSTRAÇÃO ====================

def get_sample_regression_data():
    """Dados de exemplo para regressão linear"""
    X = [[1], [2], [3], [4], [5], [6], [7], [8], [9], [10]]
    y = [2.1, 4.3, 6.2, 8.1, 10.0, 11.8, 14.1, 15.9, 18.0, 20.2]
    return X, y

def get_sample_classification_data():
    """Dados de exemplo para classificação KNN"""
    # Dados simples: classificação por tipo de flor (simplificado)
    X = [
        [5.1, 3.5], [4.9, 3.0], [4.7, 3.2], [4.6, 3.1], [5.0, 3.6],
        [7.0, 3.2], [6.4, 3.2], [6.9, 3.1], [6.5, 2.8], [6.3, 3.3],
        [6.3, 2.8], [5.8, 2.7], [7.1, 3.0], [6.3, 2.9], [6.5, 3.0]
    ]
    y = [
        "setosa", "setosa", "setosa", "setosa", "setosa",
        "versicolor", "versicolor", "versicolor", "versicolor", "versicolor",
        "virginica", "virginica", "virginica", "virginica", "virginica"
    ]
    return X, y

# ==================== MAIN ====================

def main():
    start_time = time.time()
    
    # Ler input do stdin
    try:
        input_data = json.load(sys.stdin)
    except Exception as e:
        output = {"error": f"Erro ao ler input: {str(e)}"}
        print(json.dumps(output))
        return
    
    model_type = input_data.get("model", "linear_regression").lower()
    features = input_data.get("features", [])
    action = input_data.get("action", "predict")  # predict ou train+predict
    
    try:
        if model_type == "linear_regression":
            model = LinearRegression()
            
            if action == "train_predict" or not features:
                X_train, y_train = get_sample_regression_data()
                model.fit(X_train, y_train)
                
                if not features:
                    features = [5.5]  # Valor padrão
            
            prediction = model.predict(features if isinstance(features[0], (int, float)) else [features[0]])
            
            output = {
                "model": "LinearRegression",
                "prediction": round(prediction, 4),
                "confidence": abs(model.r_squared),
                "features": features,
                "modelInfo": {
                    "slope": round(model.slope, 4),
                    "intercept": round(model.intercept, 4),
                    "rSquared": round(model.r_squared, 4)
                },
                "note": "Modelo treinado com dados de exemplo (y ≈ 2x)"
            }
        
        elif model_type == "knn":
            k = input_data.get("k", 3)
            model = KNNClassifier(k=k)
            
            X_train, y_train = get_sample_classification_data()
            model.fit(X_train, y_train)
            
            if not features:
                features = [6.0, 3.0]  # Valor padrão
            
            prediction = model.predict(features)
            probabilities = model.predict_proba(features)
            
            output = {
                "model": f"KNN(k={k})",
                "prediction": prediction,
                "confidence": max(probabilities.values()) if probabilities else 0,
                "features": features,
                "probabilities": {k: round(v, 4) for k, v in probabilities.items()},
                "classes": model.classes,
                "note": "Classificação de flores Iris simplificada"
            }
        
        elif model_type == "decision_stump":
            model = DecisionStump()
            
            X_train, y_train = get_sample_classification_data()
            model.fit(X_train, y_train)
            
            if not features:
                features = [6.0, 3.0]
            
            prediction = model.predict(features)
            
            output = {
                "model": "DecisionStump",
                "prediction": prediction,
                "confidence": model.accuracy,
                "features": features,
                "modelInfo": {
                    "splitFeature": f"feature_{model.feature_index}",
                    "threshold": round(model.threshold, 4),
                    "accuracy": round(model.accuracy, 4)
                },
                "note": "Árvore de decisão simples (1 nível)"
            }
        
        else:
            models = ["linear_regression", "knn", "decision_stump"]
            raise ValueError(f"Modelo desconhecido: {model_type}. Disponíveis: {models}")
        
        elapsed_ms = (time.time() - start_time) * 1000
        output["processingTimeMs"] = round(elapsed_ms, 4)
        output["timestamp"] = time.strftime("%Y-%m-%dT%H:%M:%S")
        
    except Exception as e:
        elapsed_ms = (time.time() - start_time) * 1000
        output = {
            "error": str(e),
            "model": model_type,
            "processingTimeMs": round(elapsed_ms, 4)
        }
    
    print(json.dumps(output))

if __name__ == "__main__":
    main()

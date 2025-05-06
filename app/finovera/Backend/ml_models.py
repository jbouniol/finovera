"""
Module de gestion des modèles de ML
"""

import joblib
import numpy as np
import pandas as pd
from typing import Dict, List

class ModelManager:
    def __init__(self):
        self.models = {}
        self.model_paths = {
            "random_forest": "models/random_forest.joblib",
            "xgboost": "models/xgboost.joblib"
        }

    def load_models(self):
        """Charge tous les modèles"""
        for name, path in self.model_paths.items():
            try:
                self.models[name] = joblib.load(path)
                print(f"✅ Modèle {name} chargé avec succès")
            except Exception as e:
                print(f"❌ Erreur lors du chargement du modèle {name}: {e}")

    def predict(self, data: pd.DataFrame) -> Dict[str, float]:
        """Fait des prédictions avec tous les modèles"""
        predictions = {}
        
        # Préparation des features
        features = self._prepare_features(data)
        
        for name, model in self.models.items():
            try:
                pred = model.predict_proba(features)[0]
                predictions[name] = pred[1]  # Probabilité de classe positive
            except Exception as e:
                print(f"❌ Erreur lors de la prédiction avec {name}: {e}")
                predictions[name] = 0.0
                
        return predictions

    def get_ensemble_score(self, predictions: Dict[str, float]) -> float:
        """Calcule le score final en combinant les prédictions"""
        if not predictions:
            return 0.0
            
        # Moyenne pondérée des prédictions
        weights = {
            "random_forest": 0.6,
            "xgboost": 0.4
        }
        
        score = 0.0
        total_weight = 0.0
        
        for name, pred in predictions.items():
            if name in weights:
                score += pred * weights[name]
                total_weight += weights[name]
                
        return score / total_weight if total_weight > 0 else 0.0

    def _prepare_features(self, data: pd.DataFrame) -> np.ndarray:
        """Prépare les features pour la prédiction"""
        # Features de base
        features = []
        
        # Prix et volume
        if 'Close' in data.columns:
            features.append(data['Close'].values)
        if 'Volume' in data.columns:
            features.append(data['Volume'].values)
            
        # Sentiment
        if 'sentiment' in data.columns:
            features.append(data['sentiment'].values)
            
        # Si pas assez de features, ajouter des zéros
        while len(features) < 3:
            features.append(np.zeros(len(data)))
            
        return np.column_stack(features) 
#!/usr/bin/env python
"""
Script d'initialisation des modèles.
Charge les données et entraîne les modèles pour les prédictions.
"""

import os
import pandas as pd
import numpy as np
import joblib
from sklearn.ensemble import RandomForestClassifier
import xgboost as xgb
from pathlib import Path

# Création du dossier models s'il n'existe pas
os.makedirs("models", exist_ok=True)

# Fonction pour créer des modèles de base
def create_fallback_models():
    print("⚠️ Création de modèles de base...")
    
    # Random Forest
    rf = RandomForestClassifier(n_estimators=100, random_state=42)
    # XGBoost
    xgb_model = xgb.XGBClassifier(n_estimators=100, random_state=42)
    
    # Enregistrement
    joblib.dump(rf, "models/random_forest.joblib")
    joblib.dump(xgb_model, "models/xgboost.joblib")
    
    print("✅ Modèles de base créés")

if __name__ == "__main__":
    try:
        # Tenter de charger les données existantes
        data_path = Path("../../data/final_dataset.csv")
        if data_path.exists():
            print(f"✅ Chargement des données depuis {data_path}")
            df = pd.read_csv(data_path)
            
            # Préparation des features
            features = ["sentiment", "Close", "Volume"]
            target = (df["variation_pct"] > 0).astype(int)
            
            # S'assurer que les features existent
            missing_features = [f for f in features if f not in df.columns]
            if missing_features:
                print(f"⚠️ Features manquantes: {missing_features}")
                create_fallback_models()
            else:
                # Entraînement des modèles
                print("🔄 Entraînement des modèles...")
                
                # Random Forest
                rf = RandomForestClassifier(n_estimators=100, random_state=42)
                rf.fit(df[features], target)
                
                # XGBoost
                xgb_model = xgb.XGBClassifier(n_estimators=100, random_state=42)
                xgb_model.fit(df[features], target)
                
                # Enregistrement
                joblib.dump(rf, "models/random_forest.joblib")
                joblib.dump(xgb_model, "models/xgboost.joblib")
                
                print("✅ Modèles entraînés et sauvegardés")
        else:
            print(f"⚠️ Fichier de données non trouvé: {data_path}")
            create_fallback_models()
    except Exception as e:
        print(f"❌ Erreur: {e}")
        create_fallback_models() 
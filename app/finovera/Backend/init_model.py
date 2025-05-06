import os
import joblib
from sklearn.ensemble import RandomForestClassifier
import xgboost as xgb

def init_model():
    # Créer le dossier models s'il n'existe pas
    os.makedirs("models", exist_ok=True)
    
    # Créer un modèle RandomForest de base
    rf_model = RandomForestClassifier(n_estimators=100, random_state=42)
    joblib.dump(rf_model, "models/random_forest.joblib")
    
    # Créer un modèle XGBoost de base
    xgb_model = xgb.XGBClassifier(n_estimators=100, random_state=42)
    joblib.dump(xgb_model, "models/xgboost.joblib")
    
    print("Modèles initialisés avec succès")

if __name__ == "__main__":
    init_model() 
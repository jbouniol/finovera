"""
train_model.py — Benchmark des modèles ML pour scoring/prédiction d’actifs (Finovera)
======================================================================================

Ce script compare plusieurs modèles supervisés classiques (Random Forest, XGBoost, etc.) pour prédire
la variation future d’un actif à partir d’un dataset enrichi (prix, volume, sentiment, macro).
- Création d’une target binaire (hausse/baisse)
- Split train/test stratifié
- Entraînement + reporting accuracy et classification_report pour chaque modèle
- Facilement extensible pour d’autres modèles ou jeux de features

Entrée : final_dataset.csv (features + target)
Sortie  : print(s) des métriques de performances

Dernière mise à jour : 2025-05-14
"""

import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.metrics import classification_report, accuracy_score
from xgboost import XGBClassifier

# === 1. CHARGEMENT DU DATASET FINAL ===
df = pd.read_csv("data/final_dataset.csv")

# === 2. CRÉATION DE LA VARIABLE CIBLE BINAIRE (HAUSSE/BAISSE) ===
df["target"] = (df["variation_pct"] > 0).astype(int)

# === 3. SELECTION DES FEATURES POUR ML ===
features = [
    "sentiment", "Open", "Close", "High", "Low", "Volume",
    "fed_rate", "unemployment_rate", "cpi"
]
X = df[features]
y = df["target"]

# === 4. SPLIT TRAIN/TEST STRATIFIÉ (80/20) ===
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# === 5. DÉFINITION DES MODÈLES À BENCHMARKER ===
models = {
    "Random Forest": RandomForestClassifier(n_estimators=100, random_state=42),
    #"Logistic Regression": LogisticRegression(max_iter=1000),
    "XGBoost": XGBClassifier(use_label_encoder=False, eval_metric='logloss')
}

# === 6. ENTRAÎNEMENT & ÉVALUATION (ACCURACY, CLASSIFICATION_REPORT) ===
for name, model in models.items():
    print(f"\n📊 {name}")
    model.fit(X_train, y_train)
    preds = model.predict(X_test)
    acc = accuracy_score(y_test, preds)
    print(f"Accuracy : {acc:.4f}")
    print(classification_report(y_test, preds))

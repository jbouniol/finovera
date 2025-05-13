import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.metrics import classification_report, accuracy_score
from xgboost import XGBClassifier

# 1. Charger le dataset
df = pd.read_csv("data/final_dataset.csv")

# 2. Créer la variable cible binaire
df["target"] = (df["variation_pct"] > 0).astype(int)

# 3. Sélection des features
features = ["sentiment", "Open", "Close", "High", "Low", "Volume",
            "fed_rate", "unemployment_rate", "cpi"]

X = df[features]
y = df["target"]

# 4. Split train/test
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

# 5. Modèles à tester
models = {
    "Random Forest": RandomForestClassifier(n_estimators=100, random_state=42),
    #"Logistic Regression": LogisticRegression(max_iter=1000),
    "XGBoost": XGBClassifier(use_label_encoder=False, eval_metric='logloss')
}

# 6. Entraînement et évaluation
for name, model in models.items():
    print(f"\n📊 {name}")
    model.fit(X_train, y_train)
    preds = model.predict(X_test)
    acc = accuracy_score(y_test, preds)
    print(f"Accuracy : {acc:.4f}")
    print(classification_report(y_test, preds))

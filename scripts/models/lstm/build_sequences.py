import pandas as pd
import numpy as np
import os
from sklearn.preprocessing import MinMaxScaler

# === CONFIG ===
DATA_PATH = "data/final_dataset.csv"
WINDOW_SIZE = 30
SELECTED_TICKERS = None  # Exemple : ["AAPL", "MSFT"] ou None pour tous
TARGET_MODE = "binary"  # ou "regression"
SAVE_PATH = "data/sequences_lstm.npz"

# === 1. CHARGEMENT DU DATASET ===
df = pd.read_csv(DATA_PATH)
df["Date"] = pd.to_datetime(df["Date"])
df.sort_values(by=["Ticker", "Date"], inplace=True)

# === 2. FILTRAGE DES TICKERS ===
if SELECTED_TICKERS:
    df = df[df["Ticker"].isin(SELECTED_TICKERS)]

# === 3. NORMALISATION DES FEATURES ===
features = ["sentiment", "Open", "High", "Low", "Close", "Volume"]
scalers = {}

X_all, y_all = [], []

for ticker in df["Ticker"].unique():
    df_t = df[df["Ticker"] == ticker].copy()
    df_t.reset_index(drop=True, inplace=True)

    # Interpolation des NaN (remplissage intelligent)
    df_t[features] = df_t[features].interpolate(method="linear", limit_direction="both")

    # Supprimer les lignes encore incomplètes
    df_t = df_t.dropna(subset=features + ["variation_pct"])
    if len(df_t) < WINDOW_SIZE + 1:
        continue  # Pas assez de données valides

    # Normalisation par ticker
    scaler = MinMaxScaler()
    df_t[features] = scaler.fit_transform(df_t[features])
    scalers[ticker] = scaler

    # Génération des séquences
    for i in range(WINDOW_SIZE, len(df_t) - 1):
        X_seq = df_t.loc[i - WINDOW_SIZE:i - 1, features].values
        y_val = df_t.iloc[i, df_t.columns.get_loc("variation_pct")]

        if TARGET_MODE == "binary":
            y_seq = int(y_val > 0)
        else:
            y_seq = y_val

        if X_seq.shape != (WINDOW_SIZE, len(features)):
            continue

        X_all.append(X_seq)
        y_all.append(y_seq)

X_all = np.array(X_all)  # shape = (nb_seq, window_size, nb_features)
y_all = np.array(y_all)  # shape = (nb_seq,) ou (nb_seq, 1)

print(f"✅ Généré {X_all.shape[0]} séquences, shape X = {X_all.shape}, y = {y_all.shape}")

# === 4. SAUVEGARDE ===
os.makedirs(os.path.dirname(SAVE_PATH), exist_ok=True)
np.savez_compressed(SAVE_PATH, X=X_all, y=y_all)
print(f"💾 Sauvegardé dans {SAVE_PATH}")

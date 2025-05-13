import numpy as np
import torch
import torch.nn as nn
import pandas as pd
from LSTM_model import LSTMModel
from sklearn.preprocessing import MinMaxScaler
import os

# === CONFIG ===
DATA_PATH = "data/final_dataset.csv"
SEQUENCE_LENGTH = 30
FEATURES = ["sentiment", "Open", "High", "Low", "Close", "Volume"]
MODEL_PATH = "data/sequences_lstm.npz"
SAVE_PATH = "data/lstm_predictions.npy"

# === CHARGEMENT DU DATASET ===
df = pd.read_csv(DATA_PATH)
df["Date"] = pd.to_datetime(df["Date"])
df.sort_values(by=["Ticker", "Date"], inplace=True)

# === CHARGEMENT DES SÉQUENCES ===
data = np.load(MODEL_PATH)
X_full = data["X"]
y_full = data["y"]

# === MODÈLE (même config que lstm_model.py) ===
IS_CLASSIFICATION = True
HIDDEN_SIZE = 64
model = LSTMModel(input_size=X_full.shape[2], hidden_size=HIDDEN_SIZE, is_classification=IS_CLASSIFICATION)
model.load_state_dict(torch.load("data/lstm_model.pt", map_location=torch.device('cpu')))
model.eval()

# === PRÉDICTIONS ===
preds_by_ticker = {}
all_dates = sorted(df["Date"].unique())
tickers = df["Ticker"].unique()

for ticker in tickers:
    df_t = df[df["Ticker"] == ticker].copy()
    df_t = df_t.sort_values("Date").reset_index(drop=True)
    df_t[FEATURES] = df_t[FEATURES].interpolate(method="linear", limit_direction="both")
    df_t.dropna(subset=FEATURES, inplace=True)

    if len(df_t) < SEQUENCE_LENGTH:
        continue

    scaler = MinMaxScaler()
    df_t[FEATURES] = scaler.fit_transform(df_t[FEATURES])

    predictions = []
    for i in range(SEQUENCE_LENGTH, len(df_t)):
        X_seq = df_t.loc[i - SEQUENCE_LENGTH:i - 1, FEATURES].values
        if X_seq.shape != (SEQUENCE_LENGTH, len(FEATURES)):
            continue

        X_tensor = torch.tensor(X_seq, dtype=torch.float32).unsqueeze(0)  # (1, seq_len, features)
        with torch.no_grad():
            out = model(X_tensor)
            proba = torch.softmax(out, dim=1)[0, 1].item() if IS_CLASSIFICATION else out.item()
            predictions.append(proba)

    # Alignement à la bonne taille (du dataset d'origine)
    padded_preds = [np.nan] * (len(df_t) - len(predictions)) + predictions
    df_t["lstm_pred"] = padded_preds
    preds_by_ticker[ticker] = df_t.set_index("Date")["lstm_pred"]

# === CONSTRUCTION MATRICE FINALE ===

# Étape 1 : supprimer les doublons dans chaque série
for ticker in preds_by_ticker:
    s = preds_by_ticker[ticker]
    s = s[~s.index.duplicated(keep="last")]  # on garde la dernière prédiction en cas de doublon
    preds_by_ticker[ticker] = s

# Étape 2 : concaténer proprement
df_preds = pd.concat(preds_by_ticker.values(), axis=1)
df_preds.columns = preds_by_ticker.keys()

# Étape 3 : nettoyage
df_preds = df_preds.sort_index()
df_preds = df_preds.dropna(how="any")

# Étape 4 : sauvegarde
pred_matrix = df_preds.values  # shape = (n_days, n_tickers)
np.save(SAVE_PATH, pred_matrix)
print(f"✅ Prédictions LSTM sauvegardées : shape = {pred_matrix.shape} → {SAVE_PATH}")@ st.cache_resource
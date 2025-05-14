"""
generate_lstm_prediction.py — Génération et alignement des prédictions LSTM par ticker pour Finovera
====================================================================================================

Ce script applique un modèle LSTM entraîné à chaque ticker du dataset pour générer des prédictions
(jour par jour) sur la probabilité de hausse (ou la variation attendue), en mode sliding window.
Il gère l’alignement temporel et la jointure des prédictions pour reconstituer une matrice finale 
(n_jours x n_tickers) synchronisée avec le dataset actions.

Entrées : final_dataset.csv, sequences_lstm.npz, lstm_model.pt
Sortie  : lstm_predictions.npy (matrice finale utilisable en features RL)

Dernière mise à jour : 2025-05-14
"""

import numpy as np
import torch
import torch.nn as nn
import pandas as pd
from LSTM_model import LSTMModel
from sklearn.preprocessing import MinMaxScaler
import os

# === CONFIGURATION DATA ET MODEL ===
DATA_PATH = "data/final_dataset.csv"
SEQUENCE_LENGTH = 30
FEATURES = ["sentiment", "Open", "High", "Low", "Close", "Volume"]
MODEL_PATH = "data/sequences_lstm.npz"
SAVE_PATH = "data/lstm_predictions.npy"

# === 1. CHARGEMENT DU DATASET ET DES SÉQUENCES ===
df = pd.read_csv(DATA_PATH)
df["Date"] = pd.to_datetime(df["Date"])
df.sort_values(by=["Ticker", "Date"], inplace=True)

data = np.load(MODEL_PATH)
X_full = data["X"]
y_full = data["y"]

# === 2. CHARGEMENT DU MODÈLE LSTM PRÉENTRAÎNÉ ===
IS_CLASSIFICATION = True
HIDDEN_SIZE = 64
model = LSTMModel(input_size=X_full.shape[2], hidden_size=HIDDEN_SIZE, is_classification=IS_CLASSIFICATION)
model.load_state_dict(torch.load("data/lstm_model.pt", map_location=torch.device('cpu')))
model.eval()

# === 3. PREDICTION JOURNALIÈRE PAR TICKER (SLIDING WINDOW) ===
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

    # Padding début : alignement avec le dataset d’origine
    padded_preds = [np.nan] * (len(df_t) - len(predictions)) + predictions
    df_t["lstm_pred"] = padded_preds
    preds_by_ticker[ticker] = df_t.set_index("Date")["lstm_pred"]

# === 4. CONSTRUCTION DE LA MATRICE FINALE (JOUR x TICKER) ===

# Étape 1 : supprime les doublons temporels par ticker
for ticker in preds_by_ticker:
    s = preds_by_ticker[ticker]
    s = s[~s.index.duplicated(keep="last")]
    preds_by_ticker[ticker] = s

# Étape 2 : concatène toutes les séries sur l’axe colonne
df_preds = pd.concat(preds_by_ticker.values(), axis=1)
df_preds.columns = preds_by_ticker.keys()

# Étape 3 : nettoyage final (dates sans prédiction sur au moins 1 ticker = drop)
df_preds = df_preds.sort_index()
df_preds = df_preds.dropna(how="any")

# Étape 4 : sauvegarde au format numpy
pred_matrix = df_preds.values  # shape = (n_days, n_tickers)
np.save(SAVE_PATH, pred_matrix)
print(f"✅ Prédictions LSTM sauvegardées : shape = {pred_matrix.shape} → {SAVE_PATH}")

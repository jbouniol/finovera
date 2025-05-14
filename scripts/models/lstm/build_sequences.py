"""
build_sequences.py — Génération de séquences supervisées pour LSTM multiactifs (Finovera)
=========================================================================================

Ce script prépare les données d’apprentissage séquentielles pour un modèle LSTM :
- Chargement et filtrage des données actions enrichies (features + targets)
- Normalisation des features par ticker (MinMaxScaler)
- Découpage glissant en séquences de longueur fixe (X), cible = variation future binaire ou continue (y)
- Support du mode classification (binaire) ou régression
- Sauvegarde dans un fichier compressé .npz compatible avec PyTorch

Entrées : final_dataset.csv
Sorties : sequences_lstm.npz (X, y)

Dernière mise à jour : 2025-05-14
"""

import pandas as pd
import numpy as np
import os
from sklearn.preprocessing import MinMaxScaler

# === CONFIGURATION DATASET & SEQUENCES ===
DATA_PATH = "data/final_dataset.csv"
WINDOW_SIZE = 30                   # Longueur de la fenêtre temporelle (séquence)
SELECTED_TICKERS = None            # Liste de tickers à garder (None = tous)
TARGET_MODE = "binary"             # "binary" pour classification, "regression" pour ML régressif
SAVE_PATH = "data/sequences_lstm.npz"

# === 1. CHARGEMENT DU DATASET ENRICHIS ===
df = pd.read_csv(DATA_PATH)
df["Date"] = pd.to_datetime(df["Date"])
df.sort_values(by=["Ticker", "Date"], inplace=True)

# === 2. FILTRAGE OPTIONNEL DES TICKERS ===
if SELECTED_TICKERS:
    df = df[df["Ticker"].isin(SELECTED_TICKERS)]

# === 3. NORMALISATION ET GÉNÉRATION DES SÉQUENCES ===
features = ["sentiment", "Open", "High", "Low", "Close", "Volume"]
scalers = {}   # Dictionnaire pour sauvegarder les scalers par ticker

X_all, y_all = [], []

for ticker in df["Ticker"].unique():
    df_t = df[df["Ticker"] == ticker].copy()
    df_t.reset_index(drop=True, inplace=True)

    # Interpolation intelligente des valeurs manquantes sur les features
    df_t[features] = df_t[features].interpolate(method="linear", limit_direction="both")

    # Suppression des lignes incomplètes (pas de NaN pour la séquence ou la cible)
    df_t = df_t.dropna(subset=features + ["variation_pct"])
    if len(df_t) < WINDOW_SIZE + 1:
        continue  # Pas assez de données valides

    # Normalisation min-max propre à chaque ticker
    scaler = MinMaxScaler()
    df_t[features] = scaler.fit_transform(df_t[features])
    scalers[ticker] = scaler

    # Découpage glissant en séquences + cible associée
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

X_all = np.array(X_all)  # (nb_sequences, window_size, nb_features)
y_all = np.array(y_all)  # (nb_sequences,)

print(f"✅ Généré {X_all.shape[0]} séquences, shape X = {X_all.shape}, y = {y_all.shape}")

# === 4. SAUVEGARDE DES SÉQUENCES AU FORMAT COMPRESSÉ ===
os.makedirs(os.path.dirname(SAVE_PATH), exist_ok=True)
np.savez_compressed(SAVE_PATH, X=X_all, y=y_all)
print(f"💾 Sauvegardé dans {SAVE_PATH}")

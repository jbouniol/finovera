"""
train_ppo.py — Entraînement RL (PPO) sur portefeuille multiactifs Finovera
==========================================================================
Ce script orchestre l’entraînement d’un agent PPO (Stable Baselines3) pour la gestion dynamique
d’un portefeuille d’actions, en utilisant des données marché, sentiment, volume et prédictions LSTM.
Il gère l’import et l’alignement des features, l’instanciation de l’environnement custom PortfolioEnv,
et la sauvegarde du modèle PPO entraîné.

Entrées : final_dataset.csv, lstm_predictions.npy
Sorties : ppo_portfolio.zip (modèle RL)

Dernière mise à jour : 2025-05-14
"""

import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../")))

import pandas as pd
import numpy as np
from stable_baselines3 import PPO
from stable_baselines3.common.vec_env import DummyVecEnv
from scripts.envs.PortfolioEnv import PortfolioEnv
import torch

# === CONFIGURATION DES FEATURES ET CHEMINS ===
DATA_PATH = "data/final_dataset.csv"
PRED_PATH = "data/lstm_predictions.npy"
MODEL_SAVE_PATH = "models/ppo_portfolio.zip"

USE_LSTM_FEATURE = True      # Inclure les prédictions LSTM dans l'observation RL
USE_SENTIMENT = True         # Inclure la feature sentiment
USE_VOLUME = True            # Inclure le volume
USE_MACRO = False            # Désactiver macroéconomie

# === 1. CHARGEMENT ET PRÉPARATION DES DONNÉES ===
df = pd.read_csv(DATA_PATH)
df["Date"] = pd.to_datetime(df["Date"])
df.sort_values(by=["Date", "Ticker"], inplace=True)

# Supprime les doublons exacts sur (Date, Ticker) en gardant la dernière
df = df.drop_duplicates(subset=["Date", "Ticker"], keep="last")

# Pivot les colonnes nécessaires pour construire les matrices (jours x tickers)
prices = df.pivot(index="Date", columns="Ticker", values="Close").values
volumes = df.pivot(index="Date", columns="Ticker", values="Volume").values if USE_VOLUME else None
sentiments = df.pivot(index="Date", columns="Ticker", values="sentiment").values if USE_SENTIMENT else None

# === 2. PRÉDICTIONS LSTM (feature avancée pour RL) ===
lstm_preds = np.load(PRED_PATH) if USE_LSTM_FEATURE else None

# Alignement temporel : on ne garde que la fenêtre commune à tous les inputs
min_days = min(prices.shape[0], lstm_preds.shape[0]) if USE_LSTM_FEATURE else prices.shape[0]
prices = prices[-min_days:]
if volumes is not None: volumes = volumes[-min_days:]
if sentiments is not None: sentiments = sentiments[-min_days:]
if lstm_preds is not None: lstm_preds = lstm_preds[-min_days:]

# Liste des tickers suivis (ordre colonne)
tickers = df["Ticker"].unique()

# === 3. INSTANTIATION DE L’ENVIRONNEMENT RL CUSTOM ===
env = DummyVecEnv([
    lambda: PortfolioEnv(
        prices=prices,
        volumes=volumes,
        sentiments=sentiments,
        lstm_predictions=lstm_preds,
        tickers=tickers,
        use_sentiment=USE_SENTIMENT,
        use_volume=USE_VOLUME,
        use_macro=USE_MACRO,
        use_lstm_pred=USE_LSTM_FEATURE
    )
])

# === 4. ENTRAÎNEMENT PPO (STABLE BASELINES3) ===
model = PPO("MlpPolicy", env, verbose=1)
model.learn(total_timesteps=10000)
model.save(MODEL_SAVE_PATH)
print(f"\n✅ Modèle PPO sauvegardé dans {MODEL_SAVE_PATH}")

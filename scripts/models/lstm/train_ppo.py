import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../")))


import pandas as pd
import numpy as np
from stable_baselines3 import PPO
from stable_baselines3.common.vec_env import DummyVecEnv
from scripts.envs.PortfolioEnv import PortfolioEnv
import torch

# === CONFIG ===
DATA_PATH = "data/final_dataset.csv"
PRED_PATH = "data/lstm_predictions.npy"
MODEL_SAVE_PATH = "models/ppo_portfolio.zip"

USE_LSTM_FEATURE = True
USE_SENTIMENT = True
USE_VOLUME = True
USE_MACRO = False

# === LOAD DATA ===
df = pd.read_csv(DATA_PATH)
df["Date"] = pd.to_datetime(df["Date"])
df.sort_values(by=["Date", "Ticker"], inplace=True)

# Supprime les doublons exacts sur (Date, Ticker) en gardant la dernière
df = df.drop_duplicates(subset=["Date", "Ticker"], keep="last")


# Pivot les colonnes nécessaires
prices = df.pivot(index="Date", columns="Ticker", values="Close").values
volumes = df.pivot(index="Date", columns="Ticker", values="Volume").values if USE_VOLUME else None
sentiments = df.pivot(index="Date", columns="Ticker", values="sentiment").values if USE_SENTIMENT else None

# === LSTM PREDICTIONS ===
lstm_preds = np.load(PRED_PATH) if USE_LSTM_FEATURE else None

# Aligner les dimensions
min_days = min(prices.shape[0], lstm_preds.shape[0]) if USE_LSTM_FEATURE else prices.shape[0]
prices = prices[-min_days:]
if volumes is not None: volumes = volumes[-min_days:]
if sentiments is not None: sentiments = sentiments[-min_days:]
if lstm_preds is not None: lstm_preds = lstm_preds[-min_days:]

# === TICKERS ===
tickers = df["Ticker"].unique()

# === ENV SETUP ===
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

# === PPO TRAINING ===
model = PPO("MlpPolicy", env, verbose=1)
model.learn(total_timesteps=10000)
model.save(MODEL_SAVE_PATH)
print(f"\n✅ Modèle PPO sauvegardé dans {MODEL_SAVE_PATH}")

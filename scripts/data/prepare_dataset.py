"""
prepare_dataset.py – Fusion, nettoyage et enrichissement du dataset actions/news pour Finovera
==============================================================================================

Ce script assemble le dataset final utilisé par les modèles ML/RL de Finovera :
- Nettoyage et typage des données de marché (prix, volume)
- Calcul des variations J+1 pour chaque ticker
- Nettoyage, analyse et agrégation journalière du sentiment à partir des news
- Fusion des variables macroéconomiques issues de macro_data.csv
- Création du fichier final_dataset.csv prêt pour le ML

Entrées : stock_data_clean.csv (marché), news_data.csv (news enrichies), macro_data.csv
Sortie : final_dataset.csv (dataset propre et enrichi, prêt à l’apprentissage)

Dernière mise à jour : 2025-05-14
"""

import pandas as pd
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

# ========== 1. CHARGEMENT DES DONNÉES RAW ==========
df_stock = pd.read_csv("data/stock_data_clean.csv")   # Données boursières pré-nettoyées
df_news = pd.read_csv("data/news_data.csv")           # News enrichies

# ========== 2. NETTOYAGE DES DONNÉES DE MARCHÉ ==========
# Conversion des types numériques (Close) et parsing des dates
df_stock["Close"] = pd.to_numeric(df_stock["Close"], errors="coerce")
df_stock["Date"] = pd.to_datetime(df_stock["Date"])

# Calcul de la variation J+1 (%) pour chaque ticker
df_stock = df_stock.sort_values(by=["Ticker", "Date"])
df_stock["next_close"] = df_stock.groupby("Ticker")["Close"].shift(-1)
df_stock["variation_pct"] = (df_stock["next_close"] - df_stock["Close"]) / df_stock["Close"]

# ========== 3. NETTOYAGE ET FORMATAGE DES NEWS ==========
df_news["date"] = pd.to_datetime(df_news["publishedAt"]).dt.date
df_news["date"] = pd.to_datetime(df_news["date"])  # Uniformisation du format date

# ========== 4. ANALYSE DE SENTIMENT DES TITRES ==========
analyzer = SentimentIntensityAnalyzer()
df_news["sentiment"] = df_news["title"].astype(str).apply(lambda x: analyzer.polarity_scores(x)["compound"])

# ========== 5. AGRÉGATION JOURNALIÈRE DU SENTIMENT PAR TICKER ==========
df_sentiment = df_news.groupby(["date", "ticker"])["sentiment"].mean().reset_index()
df_sentiment.rename(columns={"date": "Date", "ticker": "Ticker"}, inplace=True)

# ========== 6. FUSION DES VARIABLES MACROÉCONOMIQUES ==========
df_macro = pd.read_csv("data/macro_data.csv")
df_macro["Date"] = pd.to_datetime(df_macro["Date"])

# ========== 7. FUSION FINALE (ACTIONS x SENTIMENT x MACRO) ==========
df_final = pd.merge(df_sentiment, df_stock, on=["Date", "Ticker"], how="inner")
df_final = pd.merge(df_final, df_macro, on="Date", how="left")

# Retrait des lignes inexploitables (valeurs manquantes critiques)
df_final.dropna(subset=["sentiment", "variation_pct"], inplace=True)

# ========== 8. ENREGISTREMENT DU DATASET FINAL ==========
df_final.to_csv("data/final_dataset.csv", index=False)
print("✅ Dataset prêt : data/final_dataset.csv")

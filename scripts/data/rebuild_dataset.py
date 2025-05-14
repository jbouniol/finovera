"""
rebuild_dataset.py – Reconstruction complète du dataset actions/news pour Finovera
=================================================================================

Ce script permet de repartir de zéro et de reconstituer un dataset à partir de la liste des tickers présents,
en re-téléchargeant :
    - Les 60 derniers jours de données boursières (cours, volumes) via yfinance
    - Les 30 derniers jours de news financières par ticker (avec scoring de sentiment)
    - L’agrégation journalière du sentiment
    - La fusion (marché × sentiment) prête pour ML/RL

Il est conçu pour reconstruire toute la base de données en cas de corruption, migration ou changement
massif du panel d’actions suivies.

Entrées : tickers du dataset actuel (ou enrichi), yfinance, NewsAPI
Sorties : final_dataset.csv et news_data.csv, intégralement réinitialisés

Dernière mise à jour : 2025-05-14
"""

import pandas as pd
import yfinance as yf
from newsapi import NewsApiClient
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from datetime import datetime, timedelta
import os

# === CONFIGURATION API & PATHS ===
NEWS_API_KEY = "f46db82b09e74db78c13b86f6d980cb2"  # Remplace par ta vraie clé
newsapi = NewsApiClient(api_key=NEWS_API_KEY)
analyzer = SentimentIntensityAnalyzer()

DATA_PATH = "data/"
FINAL_DATASET = DATA_PATH + "final_dataset.csv"
NEWS_DATA = DATA_PATH + "news_data.csv"

os.makedirs(DATA_PATH, exist_ok=True)

# === 1. EXTRACTION DE LA LISTE DE TICKERS ===
try:
    df_existing = pd.read_csv(FINAL_DATASET)
    tickers = df_existing["Ticker"].unique().tolist()
except:
    print("⚠️ Aucune base existante. Veuillez d'abord créer ou enrichir les tickers.")
    tickers = []

# === 2. RECONSTRUCTION DATASET PAR TICKER ===
all_final = []   # Liste des DataFrames d'actions (marché x sentiment) à concaténer
all_news = []    # Liste des DataFrames de news scorées à concaténer

start_stock = (datetime.today() - timedelta(days=75)).date()  # Fenêtre marché ~2.5 mois
start_news = (datetime.today() - timedelta(days=30)).date()   # Fenêtre news 1 mois
end_date = datetime.today().date()

for ticker in tickers:
    print(f"🔁 {ticker} - récupération des 60 derniers jours...")

    # 2.1 Données boursières
    df_stock = yf.download(ticker, start=start_stock.isoformat(), end=end_date.isoformat(), auto_adjust=False)
    if isinstance(df_stock.columns, pd.MultiIndex):
        df_stock.columns = df_stock.columns.get_level_values(0)  # Aplatit le MultiIndex
    if df_stock.empty:
        print(f"❌ Pas de données pour {ticker}")
        continue

    df_stock = df_stock.copy()
    df_stock.reset_index(inplace=True)
    df_stock["Ticker"] = ticker
    df_stock = df_stock[["Date", "Ticker", "Open", "High", "Low", "Close", "Volume"]]
    df_stock.sort_values("Date", inplace=True)
    df_stock["next_close"] = df_stock["Close"].shift(-1)
    df_stock["variation_pct"] = (df_stock["next_close"] - df_stock["Close"]) / df_stock["Close"]
    print(f"📈 {ticker} - {len(df_stock)} lignes boursières récupérées.")

    # 2.2 News & analyse de sentiment
    news = newsapi.get_everything(
        q=ticker,
        from_param=start_news.isoformat(),
        to=end_date.isoformat(),
        language="en",
        sort_by="relevancy",
        page_size=50
    )
    print(f"📰 {ticker} - {len(news['articles'])} articles récupérés.")
    df_n = pd.DataFrame([{
        "ticker": ticker,
        "title": a["title"],
        "publishedAt": a["publishedAt"],
        "source": a["source"]["name"],
        "url": a["url"],
        "sentiment": analyzer.polarity_scores(a["title"])["compound"]
    } for a in news["articles"]])

    if df_n.empty:
        print(f"⚠️ Aucune news pour {ticker}")
        continue

    df_n["date"] = pd.to_datetime(df_n["publishedAt"]).dt.date
    df_n["date"] = pd.to_datetime(df_n["date"])
    all_news.append(df_n)

    # 2.3 Agrégation du sentiment jour x ticker
    df_sentiment = df_n.groupby("date")["sentiment"].mean().reset_index()
    df_sentiment.rename(columns={"date": "Date"}, inplace=True)
    df_sentiment["Ticker"] = ticker

    # 2.4 Fusion marché + sentiment (jointure outer pour robustesse)
    df_final = pd.merge(df_sentiment, df_stock, on=["Date", "Ticker"], how="outer")
    df_final = df_final[["Date", "Ticker", "sentiment", "variation_pct", "Open", "Close", "High", "Low", "Volume"]]
    #df_final.dropna(subset=["sentiment", "variation_pct"], inplace=True)

    # Imputation des valeurs manquantes de sentiment
    sentiment_imputed = (
        df_final.groupby("Ticker")["sentiment"]
        .transform(lambda s: s.ffill().bfill())
    )
    sentiment_imputed = sentiment_imputed.fillna(0.0)
    df_final["sentiment"] = sentiment_imputed

    # 2.5 Filtrage : on ne garde que les tickers avec au moins 30 jours valides
    if len(df_final) < 30:
        print(f"⚠️ Moins de 30 jours valides pour {ticker} ({len(df_final)} lignes)")
        continue

    all_final.append(df_final)
    print(f"✅ {ticker} → {len(df_final)} lignes prêtes.")

# === 3. SAUVEGARDE DES DATASETS AGREGÉS ===
if all_final:
    df_concat = pd.concat(all_final, ignore_index=True)
    df_concat.to_csv(FINAL_DATASET, index=False)
    print(f"💾 final_dataset.csv mis à jour ({len(df_concat)} lignes)")

if all_news:
    df_news_all = pd.concat(all_news, ignore_index=True)
    df_news_all.to_csv(NEWS_DATA, index=False)
    print(f"📰 news_data.csv mis à jour ({len(df_news_all)} articles)")

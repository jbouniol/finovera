import pandas as pd
import yfinance as yf
from newsapi import NewsApiClient
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from datetime import datetime, timedelta
import os

# === CONFIG ===
NEWS_API_KEY = "f46db82b09e74db78c13b86f6d980cb2"  # Remplace par ta vraie clé
newsapi = NewsApiClient(api_key=NEWS_API_KEY)
analyzer = SentimentIntensityAnalyzer()

DATA_PATH = "data/"
FINAL_DATASET = DATA_PATH + "final_dataset.csv"
NEWS_DATA = DATA_PATH + "news_data.csv"

os.makedirs(DATA_PATH, exist_ok=True)

# === 1. Charger tous les tickers connus
try:
    df_existing = pd.read_csv(FINAL_DATASET)
    tickers = df_existing["Ticker"].unique().tolist()
except:
    print("⚠️ Aucune base existante. Veuillez d'abord créer ou enrichir les tickers.")
    tickers = []

# === 2. Boucler sur tous les tickers et récupérer 60 jours
all_final = []
all_news = []

start_stock = (datetime.today() - timedelta(days=75)).date()
start_news = (datetime.today() - timedelta(days=30)).date()
end_date = datetime.today().date()

for ticker in tickers:
    print(f"🔁 {ticker} - récupération des 60 derniers jours...")

    # Données boursières
    df_stock = yf.download(ticker, start=start_stock.isoformat(), end=end_date.isoformat(), auto_adjust=False)

    if isinstance(df_stock.columns, pd.MultiIndex):
        df_stock.columns = df_stock.columns.get_level_values(0)  # Aplatit le MultiIndex

    if df_stock.empty:
        print(f"❌ Pas de données pour {ticker}")
        continue

    df_stock = df_stock.copy()
    df_stock.reset_index(inplace=True)
    df_stock["Ticker"] = ticker

    # Ne garde que les colonnes utiles
    df_stock = df_stock[["Date", "Ticker", "Open", "High", "Low", "Close", "Volume"]]
    df_stock.sort_values("Date", inplace=True)
    df_stock["next_close"] = df_stock["Close"].shift(-1)
    df_stock["variation_pct"] = (df_stock["next_close"] - df_stock["Close"]) / df_stock["Close"]

    print(f"📈 {ticker} - {len(df_stock)} lignes boursières récupérées.")
    # News
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

    df_sentiment = df_n.groupby("date")["sentiment"].mean().reset_index()
    df_sentiment.rename(columns={"date": "Date"}, inplace=True)
    df_sentiment["Ticker"] = ticker

    # Fusion
    df_final = pd.merge(df_sentiment, df_stock, on=["Date", "Ticker"], how="outer")
    df_final = df_final[["Date", "Ticker", "sentiment", "variation_pct", "Open", "Close", "High", "Low", "Volume"]]
    #df_final.dropna(subset=["sentiment", "variation_pct"], inplace=True)

    if len(df_final) < 30:
        print(f"⚠️ Moins de 30 jours valides pour {ticker} ({len(df_final)} lignes)")
        continue

    all_final.append(df_final)
    print(f"✅ {ticker} → {len(df_final)} lignes prêtes.")

# === 3. Sauvegarde
if all_final:
    df_concat = pd.concat(all_final, ignore_index=True)
    df_concat.to_csv(FINAL_DATASET, index=False)
    print(f"💾 final_dataset.csv mis à jour ({len(df_concat)} lignes)")

if all_news:
    df_news_all = pd.concat(all_news, ignore_index=True)
    df_news_all.to_csv(NEWS_DATA, index=False)
    print(f"📰 news_data.csv mis à jour ({len(df_news_all)} articles)")

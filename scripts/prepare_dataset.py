import pandas as pd
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

# ========== 1. CHARGEMENT ==========

df_stock = pd.read_csv("data/stock_data_clean.csv")
df_news = pd.read_csv("data/news_data.csv")

# ========== 2. NETTOYAGE STOCKS ==========

# Forcer les types numériques
df_stock["Close"] = pd.to_numeric(df_stock["Close"], errors="coerce")
df_stock["Date"] = pd.to_datetime(df_stock["Date"])

# Calcul variation J+1 (%)
df_stock = df_stock.sort_values(by=["Ticker", "Date"])
df_stock["next_close"] = df_stock.groupby("Ticker")["Close"].shift(-1)
df_stock["variation_pct"] = (df_stock["next_close"] - df_stock["Close"]) / df_stock["Close"]

# ========== 3. NETTOYAGE NEWS ==========

df_news["date"] = pd.to_datetime(df_news["publishedAt"]).dt.date
df_news["date"] = pd.to_datetime(df_news["date"])  # Uniformiser avec df_stock

# ========== 4. ANALYSE DE SENTIMENT ==========

analyzer = SentimentIntensityAnalyzer()
df_news["sentiment"] = df_news["title"].astype(str).apply(lambda x: analyzer.polarity_scores(x)["compound"])

# ========== 5. AGRÉGATION JOURNALIÈRE DU SENTIMENT ==========

df_sentiment = df_news.groupby(["date", "ticker"])["sentiment"].mean().reset_index()
df_sentiment.rename(columns={"date": "Date", "ticker": "Ticker"}, inplace=True)

# ========== 6. FUSION FINALE ==========

df_final = pd.merge(df_sentiment, df_stock, on=["Date", "Ticker"], how="inner")

# Optionnel : garder que les colonnes utiles
df_final = df_final[["Date", "Ticker", "sentiment", "variation_pct", "Open", "Close", "High", "Low", "Volume"]]

# Supprimer les lignes avec valeurs manquantes
df_final.dropna(subset=["sentiment", "variation_pct"], inplace=True)

# ========== 7. ENREGISTREMENT ==========
df_final.to_csv("data/final_dataset.csv", index=False)
print("✅ Dataset prêt : data/final_dataset.csv")

import yfinance as yf
import streamlit as st
from newsapi import NewsApiClient
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
import datetime
import os
import pandas as pd
import joblib
from notebooks.train_model import models, features  # réutilise les features du training
from notebooks.tickers_metadata import tickers_metadata
import matplotlib.pyplot as plt
import pydeck as pdk
import traceback


# NewsAPI config
NEWS_API_KEY = "e67a21b3ecc14ee395ea4256670b8af7"
newsapi = NewsApiClient(api_key=NEWS_API_KEY)
analyzer = SentimentIntensityAnalyzer()

def enrich_and_update_tickers(tickers_to_add,
                               dataset_path="data/final_dataset.csv",
                               stock_base_path="data/stock_data_clean.csv",
                               news_base_path="data/news_data.csv"):
    if not tickers_to_add:
        return None

    # Chargement des bases existantes
    try:
        df_final_existing = pd.read_csv(dataset_path)
        df_final_existing["Date"] = pd.to_datetime(df_final_existing["Date"])
    except FileNotFoundError:
        df_final_existing = pd.DataFrame()

    try:
        df_news_existing = pd.read_csv(news_base_path)
    except FileNotFoundError:
        df_news_existing = pd.DataFrame()

    all_final = []
    all_news = []

    for ticker in tickers_to_add:
        try:
            st.info(f"\U0001F4E1 Téléchargement des données pour {ticker}...")

            # === 1. Données boursières ===
            stock_df = yf.download(ticker, period="2mo")
            if stock_df.empty:
                st.error(f"❌ Pas de données boursières pour {ticker}")
                continue

            stock_df.reset_index(inplace=True)

            # Flatten si MultiIndex
            if isinstance(stock_df.columns, pd.MultiIndex):
                stock_df.columns = [col[0] if col[1] == '' else f"{col[0]}_{col[1]}" for col in stock_df.columns]

            required_cols = [f"{col}_{ticker}" for col in ["Open", "High", "Low", "Close", "Volume"]]
            missing_cols = [col for col in required_cols if col not in stock_df.columns]

            if missing_cols:
                st.error(f"❌ Colonnes manquantes pour {ticker} : {missing_cols}")
                continue

            # Reconstruction tidy
            df_tidy = pd.DataFrame({
                "Date": pd.to_datetime(stock_df["Date"]),
                "Ticker": ticker,
                "Open": pd.to_numeric(stock_df.get(f"Open_{ticker}"), errors="coerce"),
                "High": pd.to_numeric(stock_df.get(f"High_{ticker}"), errors="coerce"),
                "Low": pd.to_numeric(stock_df.get(f"Low_{ticker}"), errors="coerce"),
                "Close": pd.to_numeric(stock_df.get(f"Close_{ticker}"), errors="coerce"),
                "Volume": pd.to_numeric(stock_df.get(f"Volume_{ticker}"), errors="coerce"),
            })
            df_tidy.dropna(subset=["Close"], inplace=True)

            # === 2. News & Sentiment ===
            today = datetime.date.today()
            last_week = today - datetime.timedelta(days=7)
            news = newsapi.get_everything(
                q=ticker,
                from_param=last_week.isoformat(),
                to=today.isoformat(),
                language="en",
                sort_by="relevancy",
                page=1,
                page_size=10,
            )

            news_df = pd.DataFrame([{
                "ticker": ticker,
                "title": a["title"],
                "publishedAt": a["publishedAt"],
                "source": a["source"]["name"],
                "url": a["url"],
                "sentiment": analyzer.polarity_scores(a["title"])['compound']
            } for a in news["articles"]])

            if news_df.empty or "sentiment" not in news_df.columns:
                st.warning(f"⚠️ Aucune news ou pas de sentiment pour {ticker}")
                continue

            news_df["sentiment"] = pd.to_numeric(news_df["sentiment"], errors="coerce")
            news_df.dropna(subset=["sentiment"], inplace=True)
            if news_df.empty:
                st.warning(f"⚠️ Toutes les valeurs de sentiment sont nulles pour {ticker}")
                continue

            news_df["date"] = pd.to_datetime(news_df["publishedAt"]).dt.date
            news_df["date"] = pd.to_datetime(news_df["date"])
            all_news.append(news_df)

            # === 3. Moyenne journalière du sentiment ===
            df_sentiment = news_df.groupby("date")["sentiment"].mean().reset_index()
            df_sentiment.rename(columns={"date": "Date"}, inplace=True)
            df_sentiment["Ticker"] = ticker

            # === 4. Merge avec données marché ===
            df_tidy = df_tidy.sort_values(by=["Ticker", "Date"])
            df_tidy["next_close"] = df_tidy.groupby("Ticker")["Close"].shift(-1)
            df_tidy["variation_pct"] = (df_tidy["next_close"] - df_tidy["Close"]) / df_tidy["Close"]

            df_merged = pd.merge(df_sentiment, df_tidy, on=["Date", "Ticker"], how="inner")
            df_merged = df_merged[["Date", "Ticker", "sentiment", "variation_pct", "Open", "Close", "High", "Low", "Volume"]]
            df_merged.dropna(subset=["sentiment", "variation_pct"], inplace=True)

            if df_merged.empty:
                st.warning(f"⚠️ Aucune ligne finale pour {ticker} après fusion.")
                continue

            all_final.append(df_merged)

        except Exception as e:
            st.error(f"❌ Erreur pour {ticker} : {e}")
            st.text(traceback.format_exc())

    if all_final:
        df_new_final = pd.concat(all_final, ignore_index=True)
        df_updated = pd.concat([df_final_existing, df_new_final], ignore_index=True)
        df_updated.to_csv(dataset_path, index=False)
        st.success(f"✅ Données ajoutées à {dataset_path}.")
    else:
        df_new_final = None

    if all_news:
        df_new_news = pd.concat(all_news, ignore_index=True)
        df_news_combined = pd.concat([df_news_existing, df_new_news], ignore_index=True)
        df_news_combined.to_csv(news_base_path, index=False)
        st.success(f"🗞️ News ajoutées à {news_base_path}.")

    return df_new_final

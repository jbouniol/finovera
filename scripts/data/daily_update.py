"""
daily_update.py – Mise à jour automatique des données marché et news pour Finovera
===================================================================================

Ce module gère la récupération quotidienne des données boursières et des actualités financières
pour chaque ticker suivi par l’application. Les données sont enrichies par l’analyse de sentiment
des titres de news. Les résultats sont sauvegardés dans deux fichiers : le dataset final (actions)
et un historique des news scorées.

Principales étapes :
- Téléchargement incrémental des prix et volumes avec yfinance
- Récupération des news récentes et scoring sentiment avec Vader
- Fusion, agrégation et sauvegarde des résultats
- Affichage en temps réel de l’avancement via Streamlit

Entrées : fichiers CSV existants (données marché, news)
Sorties : CSV mis à jour (final_dataset.csv, news_data.csv), feedback Streamlit

Dernière mise à jour : 2025-05-14
"""

import pandas as pd
import yfinance as yf
from newsapi import NewsApiClient
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
import datetime
import os
import traceback
import streamlit as st

# === CONFIGURATION API ET CHEMINS ===
NEWS_API_KEY = "e67a21b3ecc14ee395ea4256670b8af7"
newsapi = NewsApiClient(api_key=NEWS_API_KEY)
analyzer = SentimentIntensityAnalyzer()

DATA_PATH = "data/"
FINAL_DATASET = DATA_PATH + "final_dataset.csv"
NEWS_DATA = DATA_PATH + "news_data.csv"

def daily_update():
    """
    Met à jour le dataset actions et le fichier news_data.csv pour tous les tickers suivis.
    Récupère les nouvelles données boursières manquantes et les dernières news pour chaque ticker.
    Analyse le sentiment des titres de news et fusionne le tout dans les fichiers finaux.
    Affiche l’avancement et les logs via Streamlit.

    - Récupère les nouveaux jours de marché manquants pour chaque ticker via yfinance
    - Pour chaque ticker, agrège les dernières news sur 7 jours glissants, calcule un score sentiment moyen par jour
    - Fusionne et sauvegarde les résultats dans les CSV du projet
    - Affiche l’avancement dans l’UI
    """
    try:
        df_final = pd.read_csv(FINAL_DATASET)
        df_final["Date"] = pd.to_datetime(df_final["Date"])
    except FileNotFoundError:
        st.error("❌ final_dataset.csv introuvable.")
        return

    all_tickers = df_final["Ticker"].unique()
    st.info(f"🔎 {len(all_tickers)} tickers trouvés dans la base à mettre à jour : {list(all_tickers)}")

    try:
        df_news = pd.read_csv(NEWS_DATA)
        df_news["date"] = pd.to_datetime(df_news["publishedAt"]).dt.date
        df_news["date"] = pd.to_datetime(df_news["date"])
    except FileNotFoundError:
        df_news = pd.DataFrame()

    all_updates = []
    new_news = []

    today = datetime.date.today()
    last_week = today - datetime.timedelta(days=7)

    with st.spinner("Mise à jour en cours..."):
        progress = st.progress(0)
        for i, ticker in enumerate(all_tickers):
            try:
                st.write(f"\n🔄 Mise à jour de {ticker}...")

                # 1. Recherche du dernier jour connu pour ce ticker
                last_date = df_final[df_final["Ticker"] == ticker]["Date"].max().date()
                start_date = last_date + datetime.timedelta(days=1)
                if start_date >= today:
                    st.write("✅ Données déjà à jour.")
                    progress.progress((i + 1) / len(all_tickers))
                    continue

                # 2. Téléchargement des données boursières manquantes via yfinance
                df_raw = yf.download(ticker, start=start_date.isoformat(), end=today.isoformat())
                if df_raw.empty:
                    st.warning(f"❌ Aucune nouvelle donnée boursière pour {ticker}")
                    progress.progress((i + 1) / len(all_tickers))
                    continue

                df_raw.reset_index(inplace=True)
                if isinstance(df_raw.columns, pd.MultiIndex):
                    # Aplatit MultiIndex si besoin
                    df_raw.columns = [col[0] if col[1] == '' else f"{col[0]}_{col[1]}" for col in df_raw.columns]

                # 3. Construction DataFrame des nouveaux jours
                df_stock = pd.DataFrame({
                    "Date": pd.to_datetime(df_raw["Date"]),
                    "Ticker": ticker,
                    "Open": pd.to_numeric(df_raw.get("Open"), errors="coerce"),
                    "High": pd.to_numeric(df_raw.get("High"), errors="coerce"),
                    "Low": pd.to_numeric(df_raw.get("Low"), errors="coerce"),
                    "Close": pd.to_numeric(df_raw.get("Close"), errors="coerce"),
                    "Volume": pd.to_numeric(df_raw.get("Volume"), errors="coerce"),
                })

                df_stock.dropna(subset=["Close"], inplace=True)
                df_stock.sort_values(by="Date", inplace=True)
                df_stock["next_close"] = df_stock["Close"].shift(-1)
                df_stock["variation_pct"] = (df_stock["next_close"] - df_stock["Close"]) / df_stock["Close"]

                last_downloaded_date = df_stock["Date"].max().date()
                if last_downloaded_date == datetime.date.today():
                    print(f"✅ Données du jour {last_downloaded_date} bien présentes.")
                else:
                    print(f"⚠️ Dernière donnée pour {ticker} : {last_downloaded_date} (pas encore aujourd’hui).")

                # 4. Récupération des news des 7 derniers jours
                try:
                    news = newsapi.get_everything(
                        q=ticker,
                        from_param=last_week.isoformat(),
                        to=today.isoformat(),
                        language="en",
                        sort_by="relevancy",
                        page=1,
                        page_size=10,
                    )
                except Exception as e:
                    if "rateLimited" in str(e):
                        st.warning(f"🛑 Limite NewsAPI atteinte pour {ticker} – skipping news.")
                        news = {"articles": []}
                    else:
                        raise e

                # 5. Calcul du score de sentiment sur les titres des news
                df_n = pd.DataFrame([{
                    "ticker": ticker,
                    "title": a["title"],
                    "publishedAt": a["publishedAt"],
                    "source": a["source"]["name"],
                    "url": a["url"],
                    "sentiment": analyzer.polarity_scores(a["title"])['compound']
                } for a in news["articles"]])

                if not df_n.empty:
                    df_n["date"] = pd.to_datetime(df_n["publishedAt"]).dt.date
                    df_n["date"] = pd.to_datetime(df_n["date"])
                    new_news.append(df_n)

                    # 6. Moyenne journalière du sentiment pour chaque jour avec news
                    df_sentiment = df_n.groupby("date")["sentiment"].mean().reset_index()
                    df_sentiment.rename(columns={"date": "Date"}, inplace=True)
                    df_sentiment["Ticker"] = ticker

                    # 7. Étend le score sentiment à tous les jours boursiers, remplit les jours sans news par 0
                    all_dates = df_stock["Date"].unique()
                    df_sentiment = df_sentiment.set_index("Date").reindex(all_dates).fillna(0.0).reset_index()
                    df_sentiment["Ticker"] = ticker

                    # 8. Fusionne prix + sentiment pour chaque jour boursier
                    df_merged = pd.merge(df_stock, df_sentiment, on=["Date", "Ticker"], how="left")

                else:
                    df_merged = df_stock.copy()
                    df_merged["sentiment"] = 0

                # 9. Préparation du dataframe final pour ce ticker
                df_merged = df_merged[["Date", "Ticker", "sentiment", "variation_pct", "Open", "Close", "High", "Low", "Volume"]]
                df_merged.dropna(subset=["variation_pct"], inplace=True)

                if df_merged.empty:
                    st.warning(f"⚠️ Pas de ligne à ajouter pour {ticker}")
                    progress.progress((i + 1) / len(all_tickers))
                    continue

                all_updates.append(df_merged)
                st.success(f"✅ {len(df_merged)} lignes ajoutées pour {ticker}")

            except Exception as e:
                st.error(f"❌ Erreur pour {ticker} : {e}")
                st.text(traceback.format_exc())

            progress.progress((i + 1) / len(all_tickers))

    # 10. Sauvegarde des nouvelles données marché
    if all_updates:
        df_new = pd.concat(all_updates, ignore_index=True)
        df_full = pd.concat([df_final, df_new], ignore_index=True)
        df_full.drop_duplicates(subset=["Date", "Ticker"], keep="last", inplace=True)

        # Garder uniquement les 30 derniers jours (rolling window)
        rolling_cutoff = df_full["Date"].max() - pd.Timedelta(days=30)
        df_full = df_full[df_full["Date"] >= rolling_cutoff]

        df_full.to_csv(FINAL_DATASET, index=False)
        st.success(f"💾 final_dataset.csv mis à jour avec {len(df_new)} nouvelles lignes")

    # 11. Sauvegarde des news enrichies
    if new_news:
        df_new_news = pd.concat(new_news, ignore_index=True)
        df_all_news = pd.concat([df_news, df_new_news], ignore_index=True)
        df_all_news.to_csv(NEWS_DATA, index=False)
        st.success(f"📰 news_data.csv mis à jour avec {len(df_new_news)} nouvelles lignes")

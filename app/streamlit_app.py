import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import plotly.express as px
import pydeck as pdk
import traceback
from PIL import Image

# Vos modules
from scripts.models.train_model import models, features
from scripts.tickers_metadata import tickers_metadata
from scripts.ticker_enrichment import enrich_and_update_tickers
from scripts.data.daily_update import daily_update

# PPO
from stable_baselines3 import PPO
from stable_baselines3.common.vec_env import DummyVecEnv
from scripts.envs.PortfolioEnv import PortfolioEnv

# Flag pour la simulation PPO
USE_SENTIMENT = True
USE_VOLUME    = True

# ========== CONFIG ==========
st.set_page_config(page_title="FinoVera", layout="wide")

# Logo
logo = Image.open("assets/logo.png")
st.image(logo, width=400)

# Thème
theme = st.sidebar.selectbox("🎨 Thème", ["Sombre", "Clair", "Trade Republic"])
if theme == "Sombre":
    st.markdown("""
        <style>
            html, body, [class*="css"] {background-color: #0E1117; color: #FAFAFA;}
            h1, h2, h3, h4 {color: #00C49A;}
            .stButton>button {background-color: #00C49A; color: white; border-radius: 8px;}
        </style>
    """, unsafe_allow_html=True)
elif theme == "Clair":
    st.markdown("""
        <style>
            html, body, [class*="css"] {background-color: #FFFFFF; color: #111111;}
            h1, h2, h3, h4 {color: #00695C;}
            .stButton>button {background-color: #00695C; color: white; border-radius: 8px;}
        </style>
    """, unsafe_allow_html=True)
else:
    st.markdown("""
        <style>
            /* Trade Republic inspired */
            html, body, [class*="css"] {background-color: #121212; color: #E0E0E0;}
            h1, h2, h3, h4 {color: #FFCC00;}
            .stButton>button {background-color: #FFCC00; color: #121212; border-radius: 8px;}
        </style>
    """, unsafe_allow_html=True)

# ========== NAVIGATION ==========
page = st.sidebar.radio("📌 Navigation", [
    "💡 Recommandations", 
    "📥 Mise à jour", 
    "🤖 Simulation IA"
])

# ------------------ PAGE RECOMMANDATIONS ------------------
if page == "💡 Recommandations":
    st.sidebar.header("🛠️ Vos préférences")
    risk_profile = st.sidebar.selectbox("Profil de risque", ["Conservateur","Modéré","Agressif"])
    countries = st.sidebar.multiselect(
        "Régions",
        options=list({m["country"] for m in tickers_metadata}),
        default=["United States"]
    )
    sectors = st.sidebar.multiselect(
        "Secteurs",
        options=list({m["sector"] for m in tickers_metadata}),
        default=["Technology"]
    )
    tickers_input = st.sidebar.text_area("📥 Votre portefeuille (un par ligne)", height=120)
    user_tickers = [t.strip().upper() for t in tickers_input.splitlines() if t.strip()]

    @st.cache_data
    def load_final():
        df = pd.read_csv("data/final_dataset.csv")
        df["Date"] = pd.to_datetime(df["Date"])
        return df
    df = load_final()

    def load_news():
        dfn = pd.read_csv("data/news_data.csv")
        dfn["date"] = pd.to_datetime(dfn["publishedAt"]).dt.date
        return dfn
    df_news = load_news()

    # Métadonnées
    df_meta = pd.DataFrame(tickers_metadata)
    df_meta = df_meta.rename(columns={"ticker":"Ticker"})
    df = df.merge(df_meta, on="Ticker", how="left")

    # Enrichissement si tickers manquants
    missing = [t for t in user_tickers if t not in df["Ticker"].unique()]
    if missing:
        st.warning(f"⚠️ {len(missing)} ticker(s) manquants, enrichissement…")
        enrich_and_update_tickers(missing)
        df = load_final().merge(df_meta, on="Ticker", how="left")

    # --- Gestion des filtres avec fallback complet ---
    # Si l'utilisateur n'a sélectionné aucune région/sectors, on affiche tout.
    if not countries and not sectors:
        df_f = df.copy()
    else:
        # On prend soit la sélection, soit toutes les valeurs dispo.
        selected_countries = countries if countries else df["country"].dropna().unique().tolist()
        selected_sectors   = sectors   if sectors   else df["sector"].dropna().unique().tolist()

        df_f = df[
            (df["country"].isin(selected_countries)) &
            (df["sector"].isin(selected_sectors))
        ]

        if not countries:
            st.sidebar.info("🌍 Aucun filtre régional sélectionné – affichage global.")
        if not sectors:
            st.sidebar.info("🏭 Aucun filtre sectoriel sélectionné – affichage global.")

        if df_f.empty:
            st.warning("⚠️ Aucun actif ne correspond à ces filtres.")
            st.stop()

    # Score & recommandations
    model = models["Random Forest"]
    model.fit(df_f[features], (df_f["variation_pct"]>0).astype(int))
    df_f = df_f.copy()
    df_f["score"] = model.predict_proba(df_f[features])[:,1]

    last = df_f[df_f["Date"]==df_f["Date"].max()]
    recos = last.sort_values("score", ascending=False).head(10)

    def sentiment_label(s):
        if s>=0.5: return "🟢 Très positif ✅"
        if s>=0.2: return "🟡 Modéré"
        if s>=0:   return "🟠 Neutre"
        return "🔴 Négatif ❌"
    recos["Sentiment"] = recos["sentiment"].apply(sentiment_label)

    st.header("✅ Top recommandations")
    st.dataframe(recos[["Ticker","name","country","Sentiment","score","variation_pct"]])

    # ——— Recos perso sur le portefeuille ———
    if user_tickers:
        st.subheader("📊 Recommandations sur votre portefeuille")
        df_portf = df[df["Ticker"].isin(user_tickers)]
        # ne prendre que la dernière date disponible
        df_portf_last = df_portf[df_portf["Date"] == df_portf["Date"].max()]
        if not df_portf_last.empty:
            # calcul du score (probabilité haussière)
            df_portf_last = df_portf_last.copy()
            df_portf_last["score"] = model.predict_proba(df_portf_last[features])[:, 1]
            # choix d’action en fonction du score
            def action_reco(s):
                if s >= 0.6:   return "✅ Garder / Renforcer"
                elif s >= 0.4: return "😐 Garder"
                else:          return "❌ Vendre"
            df_portf_last["Action recommandée"] = df_portf_last["score"].apply(action_reco)
            st.dataframe(
                df_portf_last[["Ticker", "name", "country", "sentiment", "score", "Action recommandée"]],
                use_container_width=True
            )
        else:
            st.warning("⚠️ Aucun résultat pour vos tickers ce jour.")
    else:
        st.info("📝 Entrez vos tickers dans la sidebar pour obtenir des recommandations personnalisées.")

    # Carte
    @st.cache_data
    def get_country_coords():
        return {
            "United States": [37.0902, -95.7129],
            "US":            [37.0902, -95.7129],
            "Mexico":        [23.6345, -102.5528],
            "Finland":       [61.9241, 25.7482],
            "United Kingdom":[55.3781, -3.4360],
            "Australia":     [-25.2744, 133.7751],
            "China":         [35.8617, 104.1954],
            "Ireland":       [53.4129, -8.2439],
            "Germany":       [51.1657, 10.4515],
            "Brazil":        [-14.2350, -51.9253],
            "Switzerland":   [46.8182, 8.2275],
            "Japan":         [36.2048, 138.2529],
            "France":        [46.6034, 1.8883],
            "Uruguay":       [-32.5228, -55.7658],
            "Canada":        [56.1304, -106.3468],
        }
    
    coords = get_country_coords()

    recos["lat"] = recos["country"].map(lambda c: coords.get(c,[0,0])[0])
    recos["lon"] = recos["country"].map(lambda c: coords.get(c,[0,0])[1])
    st.subheader("🗺️ Carte géographique")
    st.pydeck_chart(pdk.Deck(
        initial_view_state=pdk.ViewState(latitude=20, longitude=0, zoom=1.2),
        layers=[pdk.Layer(
            "ScatterplotLayer", data=recos,
            get_position="[lon, lat]", get_radius=500000,
            get_color="[200,30,0,160]"
        )]
    ))

    # News
    st.subheader("📰 Dernières news influentes")
    for t in recos["Ticker"]:
        st.markdown(f"#### {t}")
        sub = df_news[(df_news["ticker"]==t)&(df_news["date"]==df_news["date"].max())]
        for _,r in sub.head(3).iterrows():
            st.write(f"- **{r['title']}** ({r['source']}) — _{r['publishedAt']}_")

# ------------------ PAGE MISE À JOUR ------------------
elif page == "📥 Mise à jour":
    st.header("📥 Mise à jour quotidienne des données")
    if st.button("🔄 Lancer la mise à jour"):
        try:
            daily_update()
            st.success("✅ Mise à jour terminée.")
        except Exception as e:
            st.error("❌ Erreur lors de la mise à jour.")
            st.text(traceback.format_exc())

# ------------------ PAGE SIMULATION PPO ------------------
else:
    st.header("🤖 Simulation PPO")

    def run_ppo():
        # On recharge les données
        df = pd.read_csv("data/final_dataset.csv")
        df["Date"] = pd.to_datetime(df["Date"])
        df = df.drop_duplicates(["Date","Ticker"], keep="last")

        # Pivot explicite pour éviter l'erreur d'arguments positionnels
        prices     = df.pivot(index="Date", columns="Ticker", values="Close").values
        volumes    = df.pivot(index="Date", columns="Ticker", values="Volume").values if USE_VOLUME    else None
        sentiments = df.pivot(index="Date", columns="Ticker", values="sentiment").values if USE_SENTIMENT else None

        preds = np.load("data/lstm_predictions.npy")
        n = min(prices.shape[0], preds.shape[0])
        prices, volumes, sentiments, preds = prices[-n:], volumes[-n:], sentiments[-n:], preds[-n:]

        tickers = df["Ticker"].unique()
        env = DummyVecEnv([lambda: PortfolioEnv(
            prices, volumes, sentiments, preds,
            tickers,
            use_sentiment=USE_SENTIMENT,
            use_volume=USE_VOLUME,
            use_macro=False,
            use_lstm_pred=True
        )])

        model = PPO.load("models/ppo_portfolio.zip")
        obs = env.reset()
        allocs, vals = [], []

        for _ in range(n):
            a, _ = model.predict(obs)
            obs, _, done, _ = env.step(a)
            allocs.append(env.get_attr("allocations")[0].copy())
            vals.append(env.get_attr("portfolio_value")[0])
            if done[0]: break

        return np.array(allocs), np.array(vals), tickers

    if st.button("🚀 Lancer la simulation"):
        allocs, vals, tks = run_ppo()
        st.success("✅ Simulation terminée")
        # Courbe de valeur
        dfv = pd.DataFrame({"Jour": np.arange(len(vals)), "Valeur": vals})
        st.plotly_chart(px.line(dfv, x="Jour", y="Valeur", title="Valeur Portefeuille"), use_container_width=True)
        # Allocation finale
        df_a = pd.DataFrame({"Ticker": tks, "Weight": allocs[-1]*100})
        df_a = df_a[df_a["Weight"]>0.1]
        st.plotly_chart(px.pie(df_a, names="Ticker", values="Weight", hole=0.5), use_container_width=True)

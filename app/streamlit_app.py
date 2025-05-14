"""
Finovera – Streamlit Dashboard + Simulation PPO avec fine-tune express
=====================================================================
Application centrale pour la gestion, l’affichage et la simulation de portefeuilles d’actions
pilotée par IA (Random Forest, PPO RL), dédiée à l’investisseur particulier.

Ce module Streamlit permet :
    • d’afficher des recommandations IA sur les actions à renforcer/vendre/garder
    • de simuler la performance de son portefeuille selon différentes contraintes de risque
    • de lancer la mise à jour automatique des données marché et news
    • d’intégrer et enrichir automatiquement de nouveaux tickers via l’UI

Pages Streamlit :
    - 💡 Recommandations : suggestions personnalisées, carte des actifs, news influentes
    - 📥 Mise à jour : actualisation des données stockées (marché, news, sentiment)
    - 🤖 Simulation IA : backtest et allocations RL avec contrainte de préservation du capital

Entrées principales : données marché enrichies, news, modèles ML/PPO, méta-tickers.
Sorties : dashboard web interactif, recommandations, résultats simulation, CSV mis à jour.

Dernière mise à jour : 2025-05-14
"""

import os
import sys
import traceback

import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import plotly.express as px
import pydeck as pdk
from PIL import Image

from stable_baselines3 import PPO
from stable_baselines3.common.vec_env import DummyVecEnv
import torch

# ===== Imports internes du projet =====
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.append(ROOT_DIR)

from scripts.models.train_model import models, features
from scripts.tickers_metadata import tickers_metadata
from scripts.ticker_enrichment import enrich_and_update_tickers
from scripts.data.daily_update import daily_update
from scripts.envs.PortfolioEnv import PortfolioEnv  # environnement RL custom

# ===== Flags globaux =====
USE_VOLUME    = True  # Active la prise en compte du volume dans PPO
USE_SENTIMENT = True  # Active la prise en compte du sentiment

# ======== CONFIG UI =========
st.set_page_config(page_title="FinoVera", layout="wide")
logo = Image.open(os.path.join("assets", "logo.png"))
st.image(logo, width=400)

# ======== THEMING =========
theme = st.sidebar.selectbox("🎨 Thème", ["Sombre", "Clair", "Trade Republic"])
if theme == "Sombre":
    st.markdown("""
        <style>
            html, body, [class*="css"] { background-color: #0E1117; color: #FAFAFA; }
            h1, h2, h3, h4 { color: #00C49A; }
            .stButton>button { background-color: #00C49A; color: white; border-radius: 8px; }
        </style>
    """, unsafe_allow_html=True)
elif theme == "Clair":
    st.markdown("""
        <style>
            html, body, [class*="css"] { background-color: #FFFFFF; color: #111111; }
            h1, h2, h3, h4 { color: #00695C; }
            .stButton>button { background-color: #00695C; color: white; border-radius: 8px; }
        </style>
    """, unsafe_allow_html=True)
else:
    st.markdown("""
        <style>
            html, body, [class*="css"] { background-color: #121212; color: #E0E0E0; }
            h1, h2, h3, h4 { color: #FFCC00; }
            .stButton>button { background-color: #FFCC00; color: #121212; border-radius: 8px; }
        </style>
    """, unsafe_allow_html=True)

# ======== NAVIGATION ========
page = st.sidebar.radio("📌 Navigation", [
    "💡 Recommandations",
    "📥 Mise à jour",
    "🤖 Simulation IA"
])

# ======== UTILS PPO RL ========

DATASET_CSV = os.path.join(ROOT_DIR, "data", "final_dataset.csv")
MODEL_PATH  = os.path.join(ROOT_DIR, "models", "ppo_portfolio.zip")

def load_dataset():
    """
    Charge et pivote le dataset principal en trois matrices DataFrame.

    Returns:
        prices (pd.DataFrame): matrice (date x ticker) des cours de clôture
        volumes (pd.DataFrame): matrice (date x ticker) des volumes échangés
        sentiments (pd.DataFrame): matrice (date x ticker) des scores de sentiment
    """
    DATE_COL = "Date"
    df = pd.read_csv(DATASET_CSV, parse_dates=[DATE_COL])
    prices     = df.pivot(index=DATE_COL, columns="Ticker", values="Close")
    volumes    = df.pivot(index=DATE_COL, columns="Ticker", values="Volume")
    sentiments = df.pivot(index=DATE_COL, columns="Ticker", values="sentiment")
    return prices, volumes, sentiments

def get_finetuned_model(env, n_tickers: int) -> PPO:
    """
    Charge le modèle PPO général puis fine-tune rapidement pour l’environnement donné
    et le nombre d’actifs choisis.

    Args:
        env (DummyVecEnv): environnement RL custom vectorisé
        n_tickers (int): nombre d’actifs dans la simulation
    Returns:
        model (PPO): modèle PPO prêt à l’emploi
    """
    path = os.path.join(ROOT_DIR, f"models/ppo_{n_tickers}.zip")
    if os.path.exists(path):
        return PPO.load(path, device="cpu")
    model = PPO.load(MODEL_PATH, device="cpu")
    model.set_env(env)
    # Réadapte la première couche du réseau à la nouvelle dimension d’observation
    in_dim = env.observation_space.shape[0]
    hidden = model.policy.mlp_extractor.policy_net[0].out_features
    for net in (model.policy.mlp_extractor.policy_net,
                model.policy.mlp_extractor.value_net):
        net[0] = torch.nn.Linear(in_dim, hidden)
        torch.nn.init.orthogonal_(net[0].weight, gain=1.0)
        torch.nn.init.zeros_(net[0].bias)
    # Fine-tuning rapide (quelques milliers de pas)
    steps = min(2000, 500 * n_tickers)
    with st.spinner(f"🔧 Fine-tuning pour {n_tickers} tickers ({steps} pas)…"):
        model.learn(total_timesteps=steps)
    model.save(path)
    return model

def run_ppo(user_portfolio: dict[str, float]):
    """
    Lance la simulation RL sur le portefeuille utilisateur (PPO).
    Args:
        user_portfolio (dict): mapping {ticker: montant}
    Returns:
        alloc_hist (list[np.ndarray]): historique des allocations à chaque pas
        value_hist (list[float]): historique de la valeur cumulée
        tickers (list[str]): tickers simulés
    """
    if not user_portfolio:
        st.warning("Veuillez saisir un portefeuille puis relancer.")
        return None, None, None
    tickers = list(user_portfolio.keys())
    weights = np.array(list(user_portfolio.values()), dtype=np.float32)
    weights /= weights.sum()
    prices, volumes, sentiments = load_dataset()
    try:
        prices     = prices[tickers]
        volumes    = volumes[tickers]    if USE_VOLUME    else None
        sentiments = sentiments[tickers] if USE_SENTIMENT else None
    except KeyError as e:
        st.error(f"❌ Ticker absent du dataset : {e}")
        return None, None, None

    env = DummyVecEnv([lambda: PortfolioEnv(
        prices=prices.values,
        volumes=(volumes.values if USE_VOLUME else None),
        sentiments=(sentiments.values if USE_SENTIMENT else None),
        tickers=tickers,
        initial_allocation=weights,
        cap_floor=cap_floor / 100
    )])

    model = get_finetuned_model(env, n_tickers=len(tickers))

    obs = env.reset()
    alloc_hist, value_hist = [], []
    done = np.array([False])
    while not done[0]:
        action, _ = model.predict(obs, deterministic=True)
        obs, rewards, done, infos = env.step(action)
        alloc_hist.append(action[0][: len(tickers)])
        value_hist.append(infos[0].get("portfolio_value",
                            env.envs[0].portfolio_value))
    return alloc_hist, value_hist, tickers

# ================= PAGE RECOMMANDATIONS ==================
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
        """Charge le CSV final et parse la colonne Date."""
        df = pd.read_csv("data/final_dataset.csv")
        df["Date"] = pd.to_datetime(df["Date"])
        return df
    df = load_final()

    def load_news():
        """Charge les dernières news enrichies et parse la date."""
        dfn = pd.read_csv("data/news_data.csv")
        dfn["date"] = pd.to_datetime(dfn["publishedAt"]).dt.date
        return dfn
    df_news = load_news()

    df_meta = pd.DataFrame(tickers_metadata).rename(columns={"ticker":"Ticker"})
    df = df.merge(df_meta, on="Ticker", how="left")

    missing = [t for t in user_tickers if t not in df["Ticker"].unique()]
    if missing:
        st.warning(f"⚠️ {len(missing)} ticker(s) manquants, enrichissement…")
        enrich_and_update_tickers(missing)
        df = load_final().merge(df_meta, on="Ticker", how="left")

    # Filtres dynamiques pays/secteur
    if not countries and not sectors:
        df_f = df.copy()
    else:
        sel_c = countries or df["country"].dropna().unique().tolist()
        sel_s = sectors   or df["sector"].dropna().unique().tolist()
        df_f = df[(df["country"].isin(sel_c)) & (df["sector"].isin(sel_s))]
        if not countries:
            st.sidebar.info("🌍 Aucun filtre régional sélectionné – affichage global.")
        if not sectors:
            st.sidebar.info("🏭 Aucun filtre sectoriel sélectionné – affichage global.")
        if df_f.empty:
            st.warning("⚠️ Aucun actif ne correspond à ces filtres.")
            st.stop()

    # Entraînement du Random Forest sur les données filtrées
    model_rf = models["Random Forest"]
    model_rf.fit(df_f[features], (df_f["variation_pct"] > 0).astype(int))
    df_f = df_f.copy()
    df_f["score"] = model_rf.predict_proba(df_f[features])[:,1]

    # Sélection des meilleures recos à la date la plus récente
    last = df_f[df_f["Date"] == df_f["Date"].max()]
    recos = last.sort_values("score", ascending=False).head(10)

    def sentiment_label(s):
        """Mappe un score de sentiment vers un label emoji explicite."""
        if s >= 0.5: return "🟢 Très positif ✅"
        if s >= 0.2: return "🟡 Modéré"
        if s >= 0:   return "🟠 Neutre"
        return "🔴 Négatif ❌"
    recos["Sentiment"] = recos["sentiment"].apply(sentiment_label)

    st.header("✅ Top recommandations")
    st.dataframe(recos[["Ticker","name","country","Sentiment","score","variation_pct"]])

    if user_tickers:
        st.subheader("📊 Recommandations sur votre portefeuille")
        df_portf = df[df["Ticker"].isin(user_tickers)]
        df_portf_last = df_portf[df_portf["Date"] == df_portf["Date"].max()]
        if not df_portf_last.empty:
            df_portf_last = df_portf_last.copy()
            df_portf_last["score"] = model_rf.predict_proba(df_portf_last[features])[:,1]
            def action_reco(s):
                """Convertit un score en action recommandée."""
                if s >= 0.6:   return "✅ Garder / Renforcer"
                elif s >= 0.4: return "😐 Garder"
                else:          return "❌ Vendre"
            df_portf_last["Action recommandée"] = df_portf_last["score"].apply(action_reco)
            st.dataframe(
                df_portf_last[["Ticker","name","country","sentiment","score","Action recommandée"]],
                use_container_width=True
            )
        else:
            st.warning("⚠️ Aucun résultat pour vos tickers ce jour.")
    else:
        st.info("📝 Entrez vos tickers dans la sidebar pour des recos perso.")

    # Carte géographique des recommandations
    @st.cache_data
    def get_country_coords():
        """Coordonnées pays pour la carte pydeck."""
        return {
            "United States": [37.0902, -95.7129], "Mexico": [23.6345, -102.5528],
            "Finland": [61.9241, 25.7482], "United Kingdom":[55.3781, -3.4360],
            "Australia":[-25.2744, 133.7751], "China":[35.8617,104.1954],
            "Ireland":[53.4129,-8.2439], "Germany":[51.1657,10.4515],
            "Brazil":[-14.2350,-51.9253], "Switzerland":[46.8182,8.2275],
            "Japan":[36.2048,138.2529], "France":[46.6034,1.8883],
            "Uruguay":[-32.5228,-55.7658], "Canada":[56.1304,-106.3468],
        }
    coords = get_country_coords()
    recos["lat"] = recos["country"].map(lambda c: coords.get(c,[0,0])[0])
    recos["lon"] = recos["country"].map(lambda c: coords.get(c,[0,0])[1])
    st.subheader("🗺️ Carte géographique")
    st.pydeck_chart(pdk.Deck(
        initial_view_state=pdk.ViewState(latitude=20, longitude=0, zoom=1.2),
        layers=[pdk.Layer("ScatterplotLayer", data=recos,
                          get_position="[lon, lat]", get_radius=500000,
                          get_color="[200,30,0,160]")]
    ))

    # News influentes
    st.subheader("📰 Dernières news influentes")
    for t in recos["Ticker"]:
        st.markdown(f"#### {t}")
        sub = df_news[(df_news["ticker"]==t)&(df_news["date"]==df_news["date"].max())]
        for _, r in sub.head(3).iterrows():
            st.write(f"- **{r['title']}** ({r['source']}) — _{r['publishedAt']}_")

# ================= PAGE MISE À JOUR ==================
elif page == "📥 Mise à jour":
    st.header("📥 Mise à jour quotidienne des données")
    if st.button("🔄 Lancer la mise à jour"):
        try:
            daily_update()
            st.success("✅ Mise à jour terminée.")
        except Exception:
            st.error("❌ Erreur lors de la mise à jour.")
            st.text(traceback.format_exc())

# ================= PAGE SIMULATION IA ==================
else:
    st.header("🤖 Simulation IA – Portefeuille personnalisé")
    # Slider capital preservation (% de capital garanti)
    cap_floor = st.slider(
        "🔒 Capital preservation (%)",
        min_value=50,
        max_value=100,
        value=90,
        step=1,
        help="90 % → la valeur ne doit jamais descendre sous 90 % du capital initial."
    )
    raw = st.text_area("📩 Votre portefeuille (TICKER montant €)", height=200)
    user_portfolio = {}
    if raw.strip():
        try:
            for line in raw.strip().split("\n"):
                t, v = line.split()
                user_portfolio[t.upper()] = float(v)
        except Exception:
            st.error("Format incorrect : TICKER montant (ex. : AAPL 300)")

    if user_portfolio and st.button("🚀 Lancer la simulation"):
        with st.spinner("Simulation en cours…"):
            try:
                allocs, vals, tks = run_ppo(user_portfolio)
                if allocs is None:
                    st.stop()
                st.subheader("Valeur cumulée du portefeuille")
                st.line_chart(pd.Series(vals, name="Valeur").to_frame())
                st.subheader("Allocations finales")
                st.bar_chart(pd.Series(allocs[-1], index=tks, name="Poids").to_frame())
            except Exception:
                st.error("Erreur pendant la simulation :")
                st.exception(traceback.format_exc())

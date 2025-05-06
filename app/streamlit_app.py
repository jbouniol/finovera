import streamlit as st
import pandas as pd
import joblib
from train_model import models, features  # réutilise les features du training
from tickers_metadata import tickers_metadata
import matplotlib.pyplot as plt
import pydeck as pdk
from ticker_enrichment import enrich_and_update_tickers
from daily_update import daily_update
import traceback
from PIL import Image


# ==================== CONFIG ====================
st.set_page_config(page_title="FinoVera", layout="centered")

logo = Image.open("assets/logo.png")
st.image(logo, width=500)

if st.sidebar.button("🔁 Appliquer le thème sélectionné"):
    st.rerun()

theme_choice = st.sidebar.selectbox("🎨 Thème", ["Dark", "Light"])
if theme_choice == "Dark":
    st.markdown("""
        <style>
            html, body, [class*="css"]  {
                background-color: #0E1117;
                color: #FAFAFA;
            }
            h1, h2, h3, h4 {
                color: #00C49A;
            }
            .stButton>button {
                background-color: #00C49A;
                color: white;
                border-radius: 8px;
                font-weight: bold;
            }
        </style>
    """, unsafe_allow_html=True)
else:
    st.markdown("""
        <style>
            html, body, [class*="css"]  {
                background-color: #FFFFFF;
                color: #111111;
            }
            h1, h2, h3, h4 {
                color: #00695C;
            }
            .stButton>button {
                background-color: #00695C;
                color: white;
                border-radius: 8px;
                font-weight: bold;
            }
        </style>
    """, unsafe_allow_html=True)

#st.title("📈 FinoVera – Votre assistant de portefeuille intelligent")



# ==================== NAVIGATION ====================
page = st.sidebar.selectbox("📌 Navigation", ["💡 Recommandations", "📥 Mise à jour des données"])

# ==================== PAGE 1 : RECOMMANDATIONS ====================
if page == "💡 Recommandations":
    st.sidebar.header("🛠️ Vos préférences")

    # Profil de risque
    risk_profile = st.sidebar.selectbox("Profil de risque", ["Conservateur", "Modéré", "Agressif"])

    # Pays
    countries = st.sidebar.multiselect(
        "Régions géographiques",
        options=list({entry["country"] for entry in tickers_metadata}),
        default=["United States"]
    )

    # Secteurs
    sectors = st.sidebar.multiselect(
        "Secteurs d’intérêt",
        options=list({entry["sector"] for entry in tickers_metadata}),
        default=["Technology"]
    )

    # Portefeuille utilisateur
    st.sidebar.subheader("📥 Votre portefeuille actuel")
    tickers_input = st.sidebar.text_area("Entrez vos tickers (un par ligne, ex: AAPL, TSLA, NVDA)", height=150)
    user_tickers = [t.strip().upper() for t in tickers_input.splitlines() if t.strip()]

    @st.cache_data
    def load_data():
        df = pd.read_csv("data/final_dataset.csv")
        df["Date"] = pd.to_datetime(df["Date"])
        return df

    df = load_data()

    

    def load_news():
        df_news = pd.read_csv("data/news_data.csv")
        df_news["date"] = pd.to_datetime(df_news["publishedAt"]).dt.date
        return df_news

    df_news = load_news()

    df_meta = pd.DataFrame(tickers_metadata)
    df_meta = df_meta.rename(columns={"ticker": "Ticker"})
    

    df = df.merge(df_meta, on="Ticker", how="left")

    tickers_base = df["Ticker"].unique().tolist()
    tickers_missing = [t for t in user_tickers if t not in tickers_base]

    if tickers_missing:
        st.warning(f"⚠️ {len(tickers_missing)} ticker(s) absents de la base. Mise à jour en cours...")
        new_rows = enrich_and_update_tickers(tickers_missing)
        if new_rows is not None:
            df = pd.read_csv("data/final_dataset.csv")
            df["Date"] = pd.to_datetime(df["Date"])
            df = df.merge(df_meta, on="Ticker", how="left")

    selected_countries = countries if countries else df["country"].dropna().unique().tolist()
    selected_sectors = sectors if sectors else df["sector"].dropna().unique().tolist()

    df_filtered = df[
        (df["country"].isin(selected_countries)) &
        (df["sector"].isin(selected_sectors))
    ]

    if df_filtered.empty:
        st.warning("⚠️ Aucun résultat ne correspond à vos filtres. Essayez d’élargir votre sélection.")
        st.stop()

    def sentiment_label(score):
        if score >= 0.5:
            return "🟢 Très positif ✅"
        elif score >= 0.2:
            return "🟡 Modérément positif"
        elif score >= 0:
            return "🟠 Neutre"
        else:
            return "🔴 Négatif ❌"

    def plot_price(df, ticker):
        df_t = df[df["Ticker"] == ticker].sort_values("Date").tail(30)
        fig, ax = plt.subplots()
        ax.plot(df_t["Date"], df_t["Close"], marker="o")
        ax.set_title(f"📈 Évolution de {ticker}")
        ax.set_ylabel("Prix de clôture")
        st.pyplot(fig)

    model = models["Random Forest"]
    model.fit(df_filtered[features], (df_filtered["variation_pct"] > 0).astype(int))
    df_filtered = df_filtered.copy()
    df_filtered["score"] = model.predict_proba(df_filtered[features])[:, 1]

    df_today = df_filtered[df_filtered["Date"] == df_filtered["Date"].max()]
    top_recos = df_today.sort_values("score", ascending=False).head(10)
    top_recos["SentimentLabel"] = top_recos["sentiment"].apply(sentiment_label)

    if user_tickers:
        df_portfolio = df[df["Ticker"].isin(user_tickers)]
        df_portfolio_today = df_portfolio[df_portfolio["Date"] == df_portfolio["Date"].max()]
        if not df_portfolio_today.empty:
            df_portfolio_today["score"] = model.predict_proba(df_portfolio_today[features])[:, 1]
            def reco_action(score):
                if score >= 0.6:
                    return "✅ Garder / Renforcer"
                elif score >= 0.4:
                    return "😐 Garder"
                else:
                    return "❌ Vendre"
            df_portfolio_today["Action recommandée"] = df_portfolio_today["score"].apply(reco_action)
            st.subheader("📊 Recommandations sur votre portefeuille")
            st.dataframe(df_portfolio_today[["Ticker", "name", "sentiment", "score", "Action recommandée"]])
        else:
            st.warning("⚠️ Aucun résultat trouvé pour vos tickers aujourd’hui.")
    else:
        st.info("Ajoutez vos tickers dans la sidebar pour voir les recommandations sur votre portefeuille.")

    @st.cache_data
    def get_country_coords():
        return {
            "US": [37.0902, -95.7129],
            "France": [46.603354, 1.888334],
            "Germany": [51.1657, 10.4515],
            "Netherlands": [52.1326, 5.2913],
            "Japan": [36.2048, 138.2529],
            "China": [35.8617, 104.1954],
            "Brazil": [-14.2350, -51.9253],
            "Global": [0, 0]
        }

    def build_map(recos, meta):
        meta_df = pd.DataFrame(tickers_metadata)
        meta_df = df_meta.rename(columns={"ticker": "Ticker"})
        joined = pd.merge(recos, meta_df, left_on="Ticker", right_on="Ticker", how="left")
        joined["country"] = joined["country_y"]
        joined.drop(columns=["country_x", "country_y"], inplace=True)
        coords = get_country_coords()
        joined["lat"] = joined["country"].apply(lambda x: coords.get(x, [0, 0])[0])
        joined["lon"] = joined["country"].apply(lambda x: coords.get(x, [0, 0])[1])

        st.pydeck_chart(pdk.Deck(
            initial_view_state=pdk.ViewState(
                latitude=20,
                longitude=0,
                zoom=1.2,
            ),
            layers=[
                pdk.Layer(
                    'ScatterplotLayer',
                    data=joined,
                    get_position='[lon, lat]',
                    get_color='[200, 30, 0, 160]',
                    get_radius=500000,
                )
            ]
        ))

    st.subheader("✅ Recommandations d’achat aujourd’hui")
    st.dataframe(top_recos[["Date", "Ticker", "name", "country",  "SentimentLabel", "score"]])

    st.subheader("📰 Dernières actualités influentes")
    for ticker in top_recos["Ticker"].unique():
        st.markdown(f"### {ticker}")
        news = df_news[(df_news["ticker"] == ticker) & (df_news["date"] == df_news["date"].max())]
        for _, row in news.head(3).iterrows():
            st.markdown(f"- **{row['title']}** ({row['source']})")
            st.markdown(f"<small>{row['publishedAt']}</small>", unsafe_allow_html=True)

    st.subheader("📉 Évolution du prix")
    for ticker in top_recos["Ticker"].unique():
        plot_price(df, ticker)

    st.subheader("🗺️ Répartition géographique des recommandations")
    build_map(top_recos, tickers_metadata)

    st.markdown("📌 *Modèle utilisé : Random Forest entraîné sur vos filtres.*")

# ==================== PAGE 2 : MISE À JOUR ====================
elif page == "📥 Mise à jour des données":
    st.header("📥 Mise à jour quotidienne des données")
    st.markdown("Clique sur le bouton ci-dessous pour lancer une mise à jour automatique des données boursières et des actualités pour tous les tickers de la base.")

    if st.button("🔄 Mettre à jour maintenant"):
        try:
            daily_update()
            st.success("✅ Mise à jour terminée avec succès.")
        except Exception as e:
            st.error("❌ Erreur lors de la mise à jour des données.")
            st.text(traceback.format_exc())

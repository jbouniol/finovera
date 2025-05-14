"""
app.py
Finovera Backend API
Created by Jonathan Bouniol on 30/04/2025.
"""

from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict
import requests
from bs4 import BeautifulSoup
from datetime import datetime, timedelta
import pandas as pd
import numpy as np
import yfinance as yf
from newsapi import NewsApiClient
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from ml_models import ModelManager
import os
from dotenv import load_dotenv
import json
import traceback

# Chargement des variables d'environnement
load_dotenv()

# Configuration
NEWS_API_KEY = os.getenv("NEWS_API_KEY", "2c451b6b24244a43b63c96cbf49ac7a7")
newsapi = NewsApiClient(api_key=NEWS_API_KEY)
analyzer = SentimentIntensityAnalyzer()

app = FastAPI(title="Finovera Reco API", version="1.0")

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Modèles de données
class Article(BaseModel):
    title: str
    url: str
    publishedAt: datetime
    source: str

class Recommendation(BaseModel):
    symbol: str
    name: str
    score: float
    allocation: float
    sector: str
    region: str

class TickerRequest(BaseModel):
    symbol: str

# Initialisation du gestionnaire de modèles
model_manager = ModelManager()

@app.on_event("startup")
def load_model():
    model_manager.load_models()

def get_ticker_info(symbol: str) -> Dict:
    """Récupère les informations d'un ticker"""
    try:
        ticker = yf.Ticker(symbol)
        info = ticker.info
        if not info:
            raise ValueError(f"Pas d'infos pour {symbol}")
        return {
            "name": info.get("shortName", symbol),
            "sector": info.get("sector", "Unknown"),
            "region": info.get("country", "Unknown")
        }
    except Exception as e:
        print(f"Erreur lors de la récupération des infos pour {symbol}: {e}")
        return {
            "name": symbol,
            "sector": "Unknown",
            "region": "Unknown"
        }

def get_market_data(symbol: str) -> pd.DataFrame:
    """Récupère les données de marché"""
    try:
        # Utiliser une période plus courte pour éviter les erreurs
        df = yf.download(symbol, period="1mo", interval="1d")
        if df.empty:
            raise ValueError(f"Pas de données pour {symbol}")
        
        # Calculer les rendements
        df['Returns'] = df['Close'].pct_change()
        
        # Ajouter des features techniques
        df['MA5'] = df['Close'].rolling(window=5).mean()
        df['MA20'] = df['Close'].rolling(window=20).mean()
        
        # Remplir les NaN
        df.fillna(0, inplace=True)
        
        return df
    except Exception as e:
        print(f"Erreur lors de la récupération des données de marché pour {symbol}: {e}")
        return pd.DataFrame()

def get_news_and_sentiment(symbol: str) -> List[Article]:
    """Récupère les actualités et calcule le sentiment"""
    articles = []
    try:
        today = datetime.now()
        last_week = today - timedelta(days=7)
        
        # Formater les dates correctement
        from_date = last_week.strftime("%Y-%m-%d")
        to_date = today.strftime("%Y-%m-%d")
        
        news = newsapi.get_everything(
            q=symbol,
            from_param=from_date,
            to=to_date,
            language="en",
            sort_by="relevancy",
            page=1,
            page_size=10
        )
        
        if not news.get("articles"):
            print(f"Pas d'articles trouvés pour {symbol}")
            return articles
            
        for article in news["articles"]:
            try:
                # Gérer les différents formats de date possibles
                published_at = article["publishedAt"]
                if "T" in published_at:
                    dt = datetime.fromisoformat(published_at.replace("Z", "+00:00"))
                else:
                    dt = datetime.strptime(published_at, "%Y-%m-%d")
                
                articles.append(Article(
                    title=article["title"],
                    url=article["url"],
                    publishedAt=dt,
                    source=article["source"]["name"]
                ))
            except Exception as e:
                print(f"Erreur lors du traitement d'un article pour {symbol}: {e}")
                continue
                
    except Exception as e:
        print(f"Erreur lors de la récupération des news pour {symbol}: {e}")
    
    return articles

def enrich_ticker(symbol: str) -> bool:
    """Enrichit les données pour un nouveau ticker"""
    try:
        # 1. Vérifier si le ticker existe
        ticker = yf.Ticker(symbol)
        info = ticker.info
        if not info:
            raise ValueError(f"Ticker {symbol} non trouvé")

        # 2. Récupérer les données historiques
        market_data = get_market_data(symbol)
        if market_data.empty:
            raise ValueError(f"Pas de données de marché pour {symbol}")

        # 3. Récupérer les news et calculer le sentiment
        news = get_news_and_sentiment(symbol)
        if not news:
            print(f"Attention: Pas de news pour {symbol}")
            

        # 4. Sauvegarder les métadonnées
        metadata = {
            "ticker": symbol,
            "name": info.get("shortName", symbol),
            "country": info.get("country", "Unknown"),
            "sector": info.get("sector", "Unknown")
        }

        # Sauvegarder dans tickers_metadata.py
        metadata_path = "tickers_metadata.py"
        try:
            with open(metadata_path, "r", encoding="utf-8") as f:
                content = f.read()
            
            # Vérifier si le ticker existe déjà
            if f'"ticker": "{symbol}"' not in content:
                insertion = f'    {{ "ticker": "{symbol}", "name": "{metadata["name"]}", "country": "{metadata["country"]}", "sector": "{metadata["sector"]}" }},\n'
                content = content.replace("tickers_metadata = [", "tickers_metadata = [\n" + insertion)
                with open(metadata_path, "w", encoding="utf-8") as f:
                    f.write(content)
                print(f"✅ Métadonnées ajoutées pour {symbol}")
        except Exception as e:
            print(f"⚠️ Erreur lors de la sauvegarde des métadonnées: {e}")

        return True

    except Exception as e:
        print(f"❌ Erreur lors de l'enrichissement de {symbol}: {e}")
        return False

def get_all_tickers_from_csv(regions: list, sectors: list):
    """Récupère tous les tickers à partir du fichier CSV avec filtrage par région et secteur"""
    try:
        # Utiliser un chemin absolu pour accéder au fichier de données
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        df_path = os.path.join(base_dir, "data", "final_dataset.csv")
        
        print(f"Lecture des données depuis: {df_path}")
        
        if not os.path.exists(df_path):
            print(f"⚠️ Fichier non trouvé: {df_path}")
            return ["AAPL", "MSFT", "GOOGL", "AMZN", "META"]
            
        df = pd.read_csv(df_path)
        
        # Récupération des métadonnées depuis le fichier tickers_metadata.py de scripts
        tickers_metadata_path = os.path.join(base_dir, "scripts", "tickers_metadata.py")
        
        # Création d'un dictionnaire de métadonnées à partir de tickers_metadata.py
        tickers_meta = {}
        try:
            # Importer les métadonnées depuis le fichier scripts/tickers_metadata.py
            import sys
            sys.path.append(base_dir)
            from scripts.tickers_metadata import tickers_metadata
            
            for meta in tickers_metadata:
                ticker = meta.get("ticker")
                if ticker:
                    tickers_meta[ticker] = {
                        "name": meta.get("name", "Unknown"),
                        "country": meta.get("country", "Unknown"),
                        "sector": meta.get("sector", "Unknown")
                    }
        except Exception as e:
            print(f"⚠️ Erreur lors du chargement des métadonnées: {e}")
        
        # Ajouter les colonnes de pays et secteur au DataFrame
        tickers = df["Ticker"].unique().tolist()
        
        # Créer un DataFrame temporaire avec les colonnes country et sector
        meta_data = []
        for ticker in tickers:
            meta = tickers_meta.get(ticker, {})
            meta_data.append({
                "Ticker": ticker,
                "country": meta.get("country", "Unknown"),
                "sector": meta.get("sector", "Unknown")
            })
        
        df_meta = pd.DataFrame(meta_data)
        
        # Fusionner les informations de métadonnées avec le DataFrame original
        df = df.merge(df_meta, on="Ticker", how="left")
        
        # Filtrage par région et secteur si spécifiés
        filtered_df = df.copy()
        if regions:
            filtered_df = filtered_df[filtered_df["country"].isin(regions)]
        if sectors:
            filtered_df = filtered_df[filtered_df["sector"].isin(sectors)]
        
        filtered_tickers = filtered_df["Ticker"].unique().tolist()
        
        if not filtered_tickers:
            print("⚠️ Aucun ticker trouvé après filtrage")
            return tickers[:10]  # Retourne les 10 premiers tickers si aucun ne correspond aux filtres
            
        return filtered_tickers
        
    except Exception as e:
        print(f"❌ Erreur lors de la récupération des tickers: {e}")
        return ["AAPL", "MSFT", "GOOGL", "AMZN", "META"]

def generate_recommendations(risk: str, regions: List[str], sectors: List[str], capital: float) -> List[Recommendation]:
    """Génère des recommandations de portefeuille"""
    print(f"Génération de recommandations: risk={risk}, regions={regions}, sectors={sectors}, capital={capital}")
    recommendations = []
    
    try:
        # Récupérer les tickers en fonction des filtres
        tickers = get_all_tickers_from_csv(regions, sectors)
        print(f"Tickers trouvés: {len(tickers)}")
        
        if not tickers:
            print("⚠️ Aucun ticker trouvé, utilisation des tickers par défaut")
            tickers = ["AAPL", "MSFT", "GOOGL", "AMZN", "META", "NVDA", "TSLA", "JPM", "JNJ", "V"]
        
        # Charger les données historiques
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        data_path = os.path.join(base_dir, "data", "final_dataset.csv")
        
        # Si le fichier de données existe, l'utiliser directement plutôt que de récupérer les données en temps réel
        if os.path.exists(data_path):
            print(f"Utilisation des données locales depuis: {data_path}")
            df = pd.read_csv(data_path)
            df["Date"] = pd.to_datetime(df["Date"])
            
            # Récupérer les informations de métadonnées
            try:
                import sys
                sys.path.append(base_dir)
                from scripts.tickers_metadata import tickers_metadata
                
                # Créer un dictionnaire des métadonnées
                ticker_info = {}
                for meta in tickers_metadata:
                    ticker = meta.get("ticker")
                    if ticker:
                        ticker_info[ticker] = {
                            "name": meta.get("name", ticker),
                            "sector": meta.get("sector", "Unknown"),
                            "country": meta.get("country", "Unknown")
                        }
            except Exception as e:
                print(f"⚠️ Erreur lors du chargement des métadonnées: {e}")
                ticker_info = {}
            
            # Limiter aux tickers sélectionnés
            df_filtered = df[df["Ticker"].isin(tickers)]
            if df_filtered.empty:
                print("⚠️ Aucune donnée pour les tickers filtrés")
                return []
            
            # Obtenir la date la plus récente
            latest_date = df_filtered["Date"].max()
            print(f"Date la plus récente: {latest_date}")
            
            # Filtrer par date récente
            latest_df = df_filtered[df_filtered["Date"] == latest_date]
            if latest_df.empty:
                # Si pas de données pour la dernière date, prendre les dernières données disponibles pour chaque ticker
                latest_df = df_filtered.groupby("Ticker").apply(lambda x: x.nlargest(1, "Date")).reset_index(drop=True)
            
            # Calculer les scores basés sur le sentiment et la variation
            for _, row in latest_df.iterrows():
                ticker = row["Ticker"]
                
                # Obtenir les métadonnées du ticker
                meta = ticker_info.get(ticker, {})
                name = meta.get("name", ticker)
                sector = meta.get("sector", "Unknown")
                region = meta.get("country", meta.get("region", "Unknown"))
                
                # Calculer le score en fonction du sentiment et de la variation prévue
                sentiment = row.get("sentiment", 0)
                var_pct = row.get("variation_pct", 0)
                
                # Normaliser le score entre 0 et 1 (sentiment est déjà entre -1 et 1)
                # Convertir sentiment de [-1,1] à [0,1]
                norm_sentiment = (sentiment + 1) / 2
                
                # Normaliser var_pct (conversion empirique)
                norm_var = min(max((var_pct + 0.05) / 0.1, 0), 1)
                
                # Score combiné, donner plus de poids au sentiment si disponible
                if sentiment != 0:
                    score = 0.7 * norm_sentiment + 0.3 * norm_var
                else:
                    score = norm_var
                
                # Ajuster en fonction du profil de risque
                risk_factor = 1.0
                if risk == "conservative":
                    risk_factor = 0.8
                elif risk == "aggressive":
                    risk_factor = 1.2
                
                score = min(max(score * risk_factor, 0), 1)
                
                # Calcul de l'allocation selon le risque
                allocation_factor = 0.0
                if risk == "conservative":
                    allocation_factor = 0.05
                elif risk == "balanced":
                    allocation_factor = 0.08
                else:  # aggressive
                    allocation_factor = 0.12
                
                # Capital est un pourcentage, il faut l'ajuster
                adjusted_capital = min(capital / 100.0, 1.0)
                allocation = 10000 * allocation_factor * adjusted_capital * score
                
                recommendations.append(Recommendation(
                    symbol=ticker,
                    name=name,
                    score=score,
                    allocation=allocation,
                    sector=sector,
                    region=region
                ))
        else:
            # Si pas de données locales, utiliser la méthode en temps réel avec YFinance
            print("⚠️ Pas de données locales, utilisation de YFinance")
            for symbol in tickers[:20]:  # Limiter à 20 tickers pour des performances optimales
                try:
                    # Récupération des données
                    market_data = get_market_data(symbol)
                    if market_data.empty:
                        print(f"Pas de données de marché pour {symbol}")
                        continue
                    
                    # Calcul du sentiment moyen
                    news = get_news_and_sentiment(symbol)
                    sentiment = np.mean([analyzer.polarity_scores(a.title)['compound'] for a in news]) if news else 0
                    
                    # Préparation des données pour la prédiction
                    latest_data = market_data.iloc[-1].copy()
                    latest_data["sentiment"] = sentiment
                    
                    # Créer un DataFrame avec les features nécessaires
                    pred_data = pd.DataFrame([{
                        'Close': latest_data['Close'],
                        'Volume': latest_data['Volume'],
                        'Returns': latest_data['Returns'],
                        'MA5': latest_data['MA5'],
                        'MA20': latest_data['MA20'],
                        'sentiment': sentiment
                    }])
                    
                    # Prédictions
                    predictions = model_manager.predict(pred_data)
                    score = model_manager.get_ensemble_score(predictions)
                    
                    # Informations du ticker
                    info = get_ticker_info(symbol)
                    
                    # Calcul de l'allocation selon le risque
                    allocation_factor = 0.0
                    if risk == "conservative":
                        allocation_factor = 0.05
                    elif risk == "balanced":
                        allocation_factor = 0.08
                    else:  # aggressive
                        allocation_factor = 0.12
                    
                    # Capital est un pourcentage, il faut l'ajuster
                    adjusted_capital = min(capital / 100.0, 1.0)
                    allocation = 10000 * allocation_factor * adjusted_capital * score
                    
                    recommendations.append(Recommendation(
                        symbol=symbol,
                        name=info["name"],
                        score=score,
                        allocation=allocation,
                        sector=info["sector"],
                        region=info["region"]
                    ))
                except Exception as e:
                    print(f"Erreur lors de l'analyse de {symbol}: {e}")
                    continue
    except Exception as e:
        print(f"Erreur lors de la génération des recommandations: {e}")
        print(traceback.format_exc())
    
    # Tri par score
    recommendations.sort(key=lambda x: x.score, reverse=True)
    print(f"Nombre de recommandations générées: {len(recommendations)}")
    return recommendations

# Endpoints
@app.get("/news")
async def get_news(symbol: str):
    articles = get_news_and_sentiment(symbol)
    return articles

@app.get("/recommendations")
async def get_recommendations(
    risk: str = Query("balanced", enum=["conservative", "balanced", "aggressive"]),
    regions: Optional[str] = None,
    sectors: Optional[str] = None,
    capital: float = 10000.0
):
    region_list = regions.split(",") if regions and regions.strip() else []
    sector_list = sectors.split(",") if sectors and sectors.strip() else []
    
    recommendations = generate_recommendations(
        risk=risk,
        regions=region_list,
        sectors=sector_list,
        capital=capital
    )
    return recommendations

@app.post("/add_ticker")
async def add_ticker(request: TickerRequest):
    """Ajoute un nouveau ticker à l'analyse"""
    success = enrich_ticker(request.symbol)
    if not success:
        raise HTTPException(status_code=400, detail=f"Impossible d'ajouter le ticker {request.symbol}")
    return {"message": f"Ticker {request.symbol} ajouté avec succès"}

@app.get("/tickers_metadata")
async def get_tickers_metadata():
    """Renvoie les métadonnées de tous les tickers"""
    try:
        from tickers_metadata import tickers_metadata
        return tickers_metadata
    except ImportError:
        # Fallback: créer une liste basique
        return [
            {"ticker": "AAPL", "name": "Apple Inc.", "country": "United States", "sector": "Technology"},
            {"ticker": "MSFT", "name": "Microsoft Corporation", "country": "United States", "sector": "Technology"},
            {"ticker": "GOOGL", "name": "Alphabet Inc.", "country": "United States", "sector": "Communication Services"},
            {"ticker": "AMZN", "name": "Amazon.com, Inc.", "country": "United States", "sector": "Consumer Cyclical"},
            {"ticker": "META", "name": "Meta Platforms, Inc.", "country": "United States", "sector": "Communication Services"},
            {"ticker": "TSLA", "name": "Tesla, Inc.", "country": "United States", "sector": "Consumer Cyclical"},
            {"ticker": "JPM", "name": "JPMorgan Chase & Co.", "country": "United States", "sector": "Financial Services"},
            {"ticker": "JNJ", "name": "Johnson & Johnson", "country": "United States", "sector": "Healthcare"},
            {"ticker": "V", "name": "Visa Inc.", "country": "United States", "sector": "Financial Services"},
            {"ticker": "PG", "name": "Procter & Gamble Company", "country": "United States", "sector": "Consumer Defensive"}
        ]

@app.get("/available_metadata")
async def get_available_metadata():
    """Renvoie les secteurs et régions disponibles"""
    try:
        from tickers_metadata import tickers_metadata
        countries = list(set(m["country"] for m in tickers_metadata))
        sectors = list(set(m["sector"] for m in tickers_metadata))
        return {
            "regions": countries,
            "sectors": sectors
        }
    except ImportError:
        # Fallback: renvoyer des valeurs par défaut
        return {
            "regions": ["United States", "Europe", "Asia", "Other"],
            "sectors": ["Technology", "Healthcare", "Consumer Cyclical", "Financial Services", "Communication Services", "Consumer Defensive", "Industrials", "Basic Materials", "Energy", "Utilities", "Real Estate"]
        }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)

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

def generate_recommendations(risk: str, regions: List[str], sectors: List[str], capital: float) -> List[Recommendation]:
    """Génère des recommandations de portefeuille"""
    recommendations = []
    
    # Liste des tickers à analyser
    tickers = ["AAPL", "MSFT", "GOOGL", "AMZN", "META", "NVDA", "TSLA"]
    
    for symbol in tickers:
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
            if risk == "conservative":
                allocation = capital * 0.1
            elif risk == "balanced":
                allocation = capital * 0.15
            else:  # aggressive
                allocation = capital * 0.2
            
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
    
    # Tri par score
    recommendations.sort(key=lambda x: x.score, reverse=True)
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
    region_list = regions.split(",") if regions else []
    sector_list = sectors.split(",") if sectors else []
    
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)

# Finovera Backend API

Ce backend fournit les données et les recommandations pour l'application iOS Finovera.

## Installation

1. Vérifiez que vous avez Python 3.8+ installé:
   ```
   python --version
   ```

2. Installez les dépendances:
   ```
   pip install -r requirements.txt
   ```

3. Initialisez les modèles:
   ```
   python init_model.py
   ```

## Démarrage du serveur

Pour lancer le serveur en mode développement:
```
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

Pour la production:
```
gunicorn app:app -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000
```

## Endpoints disponibles

- `GET /recommendations`: Obtenir des recommandations de portefeuille
  - Paramètres: 
    - `risk`: "conservative", "balanced", ou "aggressive"
    - `regions`: Liste de régions séparées par des virgules 
    - `sectors`: Liste de secteurs séparés par des virgules
    - `capital`: Montant du capital à investir (en %)

- `GET /news`: Obtenir les dernières actualités pour un titre
  - Paramètres:
    - `symbol`: Le symbole boursier (ex: "AAPL")

- `POST /add_ticker`: Ajouter un nouveau titre à l'analyse
  - Body: `{"symbol": "AAPL"}`

- `GET /tickers_metadata`: Obtenir les métadonnées de tous les titres

- `GET /available_metadata`: Obtenir la liste des régions et secteurs disponibles

## Configuration

Créez un fichier `.env` dans le dossier backend avec les variables suivantes:
```
NEWS_API_KEY=votre_clé_api_news
```

## Synchronisation avec l'application iOS

Assurez-vous que l'adresse IP dans l'application iOS correspond à l'adresse où tourne ce serveur. 
L'adresse par défaut dans l'application est `localhost:8000`.

## Documentation API

La documentation interactive de l'API est disponible aux adresses :
- Swagger UI : http://127.0.0.1:8000/docs
- ReDoc : http://127.0.0.1:8000/redoc 
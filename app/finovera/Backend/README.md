# Finovera Backend API

API backend pour l'application Finovera iOS, fournissant des recommandations de portefeuille et des actualités financières.

## Installation

1. Créez un environnement virtuel Python :
```bash
python -m venv venv
source venv/bin/activate  # Sur Unix/MacOS
# ou
.\venv\Scripts\activate  # Sur Windows
```

2. Installez les dépendances :
```bash
pip install -r requirements.txt
```

## Lancement de l'API

Pour démarrer l'API en mode développement :
```bash
uvicorn app:app --reload
```

L'API sera accessible à l'adresse : http://127.0.0.1:8000

## Endpoints

### 1. Recommandations de portefeuille
```
GET /recommendations
```

Paramètres :
- `risk` : Niveau de risque (string)
- `regions` : Liste des régions séparées par des virgules (optionnel)
- `sectors` : Liste des secteurs séparés par des virgules (optionnel)
- `capital` : Montant du capital à investir (float, par défaut 10000.0)

### 2. Actualités financières
```
GET /news
```

Paramètres :
- `symbol` : Symbole boursier (ex: AAPL, MSFT)

## Documentation API

La documentation interactive de l'API est disponible aux adresses :
- Swagger UI : http://127.0.0.1:8000/docs
- ReDoc : http://127.0.0.1:8000/redoc 
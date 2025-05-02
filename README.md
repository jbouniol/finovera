# finovera

**Finovera** est une application intelligente qui recommande un portefeuille d’actions personnalisé en fonction du profil de chaque investisseur.
Grâce à un **AI-Agent**, l’utilisateur bénéficie de recommandations financières sur mesure, basées sur une analyse combinant données de marché, théorie moderne du portefeuille et préférences personnelles (aversion au risque, objectifs de rendement, horizon d’investissement, etc.).

---

## Ressources du projet

Tu peux retrouver l'ensemble des datasets ici :
📁 [Google Drive – Dossier Finovera](https://drive.google.com/drive/u/0/folders/1PNcL4oUCxw4gNcUsCxsghxd8MGpYGiTq)

---

1. Type de données, méthodes employées, sources et objectif (8 points)

Nous utilisons deux types principaux de données :
	•	Données financières historiques : prix d’ouverture, de fermeture, plus haut, plus bas, volume, variation quotidienne (%) pour des actions ou ETF. Ces données sont collectées via l’API Yahoo Finance à l’aide du package Python yfinance.
	•	Actualités financières : titres et dates d’articles de presse en lien avec chaque ticker, provenant de l’API NewsAPI. Chaque titre est analysé à l’aide du modèle VADER (analyse lexicale de sentiment) pour produire un score de sentiment journalier par actif.

Objectif : croiser ces deux sources pour construire un indicateur de recommandation quotidien pour chaque actif financier, en tenant compte à la fois du contexte de marché et de l’opinion des médias.

Méthodes :
	•	Fusion temporelle des données boursières et des scores de sentiment.
	•	Nettoyage et traitement pour gérer les valeurs manquantes (forward/backward fill, exclusion des lignes incomplètes).
	•	Enrichissement automatique des tickers avec métadonnées (secteur, pays) via yfinance et règles manuelles pour les ETF.
	•	Sauvegarde continue des données (final_dataset.csv et news_data.csv) pour exploitation dans l’application Streamlit.

⸻

2. Méthodes de machine learning utilisées et justification (6 points)

Nous avons testé plusieurs modèles de classification pour prédire la variation journalière d’un actif à partir du score de sentiment et d’autres variables (prix, volume) :
	•	Random Forest (choix final) : sélectionné pour sa robustesse aux valeurs manquantes et aux corrélations non linéaires, ainsi que pour son interprétabilité.
	•	Autres modèles testés : LogisticRegression (sensibilité aux NaN), XGBoost (performant mais plus coûteux en calcul), et une version préliminaire de LSTM (non retenue car trop complexe pour les données disponibles).

Le modèle est entraîné à chaque lancement en fonction des filtres de l’utilisateur (secteur, région) pour produire des scores de probabilité d’évolution positive. Les 5 actifs avec les scores les plus élevés sont recommandés à l’achat chaque jour.

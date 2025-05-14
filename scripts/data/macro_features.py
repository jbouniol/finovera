"""
macro_features.py – Importation et agrégation des variables macroéconomiques (FRED) pour Finovera
==================================================================================================

Ce script télécharge automatiquement des indicateurs macroéconomiques clés (taux Fed, chômage US,
indice des prix CPI) depuis la Federal Reserve Economic Data (FRED), puis crée un fichier `macro_data.csv`
agrégé jour par jour. Il fusionne ensuite ces données avec le dataset principal actions pour enrichir
les modèles de machine learning utilisés par Finovera.

Étapes clés :
- Téléchargement incrémental des séries macro FRED (taux directeur, chômage, CPI)
- Agrégation en une seule table à pas journalier (remplissage ffill)
- Sauvegarde dans data/macro_data.csv
- Option : fusion automatique avec le dataset actions existant (data/final_dataset.csv)

Entrées : API FRED (via clé), CSV local actions
Sorties : CSV macro enrichi, CSV actions enrichi

Dernière mise à jour : 2025-05-14
"""

import pandas as pd
import datetime
from fredapi import Fred

# === CONFIGURATION API ET VARIABLES ===
FRED_API_KEY = "1d1e938459e25d8d518208dbc28b30b7"  # Remplace par ta vraie clé API FRED
fred = Fred(api_key=FRED_API_KEY)

# Indicateurs macro à importer : {FRED code : nom colonne dans le CSV final}
MACRO_INDICATORS = {
    "FEDFUNDS": "fed_rate",               # Taux directeur Fed (court terme)
    "UNRATE": "unemployment_rate",        # Taux de chômage US
    "CPIAUCSL": "cpi"                     # Indice prix à la consommation US (inflation)
}

# Fenêtre temporelle par défaut
START_DATE = "2020-01-01"
END_DATE = datetime.date.today().isoformat()

# === RECUPERATION & AGREGRATION JOURNALIERE ===
macro_data = pd.DataFrame()

for fred_code, col_name in MACRO_INDICATORS.items():
    print(f"⬆️ Téléchargement de {col_name} ({fred_code})")
    series = fred.get_series(fred_code, observation_start=START_DATE, observation_end=END_DATE)
    df = pd.DataFrame({"Date": series.index, col_name: series.values})
    df["Date"] = pd.to_datetime(df["Date"])
    df = df.set_index("Date").resample("D").ffill().reset_index()  # interpolation à la journée, remplissage progressif

    if macro_data.empty:
        macro_data = df
    else:
        macro_data = pd.merge(macro_data, df, on="Date", how="outer")

# === EXPORT CSV MACRO FINAL ===
macro_data.sort_values("Date", inplace=True)
macro_data.to_csv("data/macro_data.csv", index=False)
print("\n✅ Données macroéconomiques enregistrées dans data/macro_data.csv")

# === (Optionnel) FUSION AVEC LE DATASET ACTIONS ===
try:
    df_final = pd.read_csv("data/final_dataset.csv")
    df_final["Date"] = pd.to_datetime(df_final["Date"])
    merged = pd.merge(df_final, macro_data, on="Date", how="left")
    merged.to_csv("data/final_dataset.csv", index=False)
    print("\n📈 Données macro fusionnées dans final_dataset.csv")
except FileNotFoundError:
    print("⚠️ final_dataset.csv non trouvé. La fusion n'a pas été faite.")

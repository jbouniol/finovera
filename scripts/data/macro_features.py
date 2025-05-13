import pandas as pd
import datetime
from fredapi import Fred

# === CONFIG ===
FRED_API_KEY = "1d1e938459e25d8d518208dbc28b30b7"  # Remplace par ta vraie clé API
fred = Fred(api_key=FRED_API_KEY)

# Variables FRED à récupérer
MACRO_INDICATORS = {
    "FEDFUNDS": "fed_rate",
    "UNRATE": "unemployment_rate",
    "CPIAUCSL": "cpi"
}

# Date de début par défaut (peut être ajustée)
START_DATE = "2020-01-01"
END_DATE = datetime.date.today().isoformat()

# === Récupération et agrégation ===
macro_data = pd.DataFrame()

for fred_code, col_name in MACRO_INDICATORS.items():
    print(f"⬆️ Téléchargement de {col_name} ({fred_code})")
    series = fred.get_series(fred_code, observation_start=START_DATE, observation_end=END_DATE)
    df = pd.DataFrame({"Date": series.index, col_name: series.values})
    df["Date"] = pd.to_datetime(df["Date"])
    df = df.set_index("Date").resample("D").ffill().reset_index()

    if macro_data.empty:
        macro_data = df
    else:
        macro_data = pd.merge(macro_data, df, on="Date", how="outer")

# Finaliser
macro_data.sort_values("Date", inplace=True)
macro_data.to_csv("data/macro_data.csv", index=False)
print("\n✅ Données macroéconomiques enregistrées dans data/macro_data.csv")

# (Optionnel) Fusion avec final_dataset
try:
    df_final = pd.read_csv("data/final_dataset.csv")
    df_final["Date"] = pd.to_datetime(df_final["Date"])
    merged = pd.merge(df_final, macro_data, on="Date", how="left")
    merged.to_csv("data/final_dataset.csv", index=False)
    print("\n📈 Données macro fusionnées dans final_dataset.csv")
except FileNotFoundError:
    print("⚠️ final_dataset.csv non trouvé. La fusion n'a pas été faite.")

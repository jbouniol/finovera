import shutil
import os

def color(text, code):
    return f"\033[{code}m{text}\033[0m"

def banner():
    print(color("\n🎨 FinoVera Theme Switcher", "1;32"))
    print(color("-" * 32, "90"))
    print("1. 🌙 Thème sombre")
    print("2. ☀️ Thème clair")
    print("3. 💹 Trade Republic")
    print("0. ❌ Quitter\n")

banner()

choice = input(color("Choisissez une option (1/2/3/0) : ", "1;36")).strip()

if choice == "1":
    shutil.copy(".streamlit/config_dark.toml", ".streamlit/config.toml")
    print(color("\n✅ Thème sombre appliqué avec succès !", "1;32"))
elif choice == "2":
    shutil.copy(".streamlit/config_light.toml", ".streamlit/config.toml")
    print(color("\n✅ Thème clair appliqué avec succès !", "1;33"))
elif choice == "3":
    shutil.copy(".streamlit/config_trade_republic.toml", ".streamlit/config.toml")
    print(color("\n✅ Thème Trade Republic appliqué avec succès !", "1;35"))
elif choice == "0":
    print(color("\n👋 À bientôt !", "90"))
else:
    print(color("\n❌ Option invalide. Veuillez entrer 1, 2, 3 ou 0.", "1;31"))

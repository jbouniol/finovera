"""
PortfolioEnv.py — Environnement Gymnasium (SB3) pour RL appliquée à la gestion d’actifs Finovera
================================================================================================

Cet environnement custom implémente la logique de gestion d’un portefeuille d’actions multi-actifs,
compatible Stable Baselines3 v2.x (Gymnasium API).  
Fonctionnalités principales :
    - Dimensions d’observation et d’action dynamiques selon le portefeuille choisi
    - Prise en compte optionnelle du volume et du sentiment
    - Support d’une contrainte stricte de préservation du capital (cap_floor)
    - Padding/trimming des observations pour garantir compatibilité avec un modèle global RL
    - Attribution automatique des allocations initiales, simulation du rendement quotidien

Entrée : matrices numpy (prix, volumes, sentiment), tickers, paramètres simulation
Sortie : environnement RL Gymnasium standard

Dernière mise à jour : 2025-05-14
"""

from __future__ import annotations
import numpy as np
import gymnasium as gym
from gymnasium import spaces

class PortfolioEnv(gym.Env):
    """
    Environnement de simulation RL pour portefeuille d’actions, compatible SB3/Gymnasium.

    Attributs principaux :
        - TARGET_DIM : dimension cible de l’espace d’observation (padding)
        - ACTION_DIM : dimension cible de l’espace d’action (trimming)
        - cap_floor  : pourcentage minimal de capital à garantir sur la période
    """
    TARGET_DIM = 449     # Dimension d'observation fixée (padding si <, trunc si >)
    ACTION_DIM = 112     # Dimension d'action fixée (seulement les N premières actives)

    def __init__(
        self,
        *,
        prices: np.ndarray,
        volumes: np.ndarray | None = None,
        sentiments: np.ndarray | None = None,
        tickers: list[str] | None = None,
        initial_allocation: np.ndarray | None = None,
        initial_cash: float = 100_000.0,
        max_allocation: float = 1.0,
        use_volume: bool = True,
        use_sentiment: bool = True,
        cap_floor: float = 0.90,   # ← capital plancher (0.5–1.0)
    ):
        """
        Initialise l’environnement de portefeuille.
        Args :
            prices (np.ndarray): prix de clôture (jours x tickers)
            volumes (np.ndarray|None): volumes (jours x tickers)
            sentiments (np.ndarray|None): scores de sentiment (jours x tickers)
            tickers (list[str]|None): labels
            initial_allocation (np.ndarray|None): poids initiaux (somme = 1)
            initial_cash (float): capital initial
            max_allocation (float): allocation max par actif (non utilisé ici)
            use_volume (bool): active volume dans l’observation
            use_sentiment (bool): active sentiment dans l’observation
            cap_floor (float): pourcentage minimal garanti sur la période
        """
        super().__init__()

        # Données marché et meta
        self.prices     = prices
        self.volumes    = volumes
        self.sentiments = sentiments
        self.n_days, self.n_tickers = prices.shape
        self.tickers = tickers or [f"T{i}" for i in range(self.n_tickers)]

        # Paramètres financiers / simulation
        self.initial_cash   = initial_cash
        self.max_allocation = max_allocation
        self.use_volume     = use_volume and (volumes is not None)
        self.use_sentiment  = use_sentiment and (sentiments is not None)
        self.cap_floor = cap_floor
        self.min_value = self.initial_cash * self.cap_floor

        # Initialisation du portefeuille et de l’état
        self.current_day    = 0
        if initial_allocation is not None:
            assert len(initial_allocation) == self.n_tickers
            self.allocations = initial_allocation.astype(np.float32)
        else:
            # Répartition uniforme si non spécifiée
            self.allocations = np.ones(self.n_tickers, dtype=np.float32) / self.n_tickers

        self.portfolio_value = float(self.initial_cash)

        # Espaces Gym (action & observation)
        self.action_space = spaces.Box(
            low=-1.0, high=1.0,
            shape=(self.ACTION_DIM,),
            dtype=np.float32
        )
        self.observation_space = spaces.Box(
            low=0.0, high=1.0,
            shape=(self.TARGET_DIM,),
            dtype=np.float32
        )

    def _get_observation(self) -> np.ndarray:
        """
        Construit le vecteur d’observation à partir de la situation courante.
        - Normalise le jour courant (0 → 1)
        - Ajoute allocations actuelles
        - Ajoute volumes normalisés si activé
        - Ajoute sentiments (scalés entre 0 et 1) si activé
        - Pad/truncate pour correspondre à TARGET_DIM
        Returns:
            obs (np.ndarray): observation prête pour le modèle RL
        """
        day_norm = self.current_day / max(1, (self.n_days - 1))
        parts = [np.array([day_norm], dtype=np.float32), self.allocations]

        if self.use_volume:
            vol_today = self.volumes[self.current_day]
            max_vol   = np.nanmax(self.volumes, axis=0)
            vol_norm  = np.where(max_vol>0, vol_today/max_vol, 0.0)
            parts.append(vol_norm.astype(np.float32))

        if self.use_sentiment:
            sent_today = self.sentiments[self.current_day]
            sent_norm  = ((sent_today + 1)/2).astype(np.float32)
            parts.append(sent_norm)

        obs = np.concatenate(parts, axis=0)
        obs = np.nan_to_num(obs, nan=0.0, posinf=1.0, neginf=0.0)

        # Pad ou tronque pour TARGET_DIM
        if obs.size < self.TARGET_DIM:
            obs = np.pad(obs, (0, self.TARGET_DIM-obs.size), constant_values=0.0)
        else:
            obs = obs[: self.TARGET_DIM]

        return obs

    def reset(self, *, seed: int | None = None, options: dict | None = None):
        """
        Réinitialise l’environnement au début de l’épisode.
        Remet le portefeuille et les allocations à zéro.
        Returns:
            obs (np.ndarray), infos (dict)
        """
        super().reset(seed=seed)
        self.current_day    = 0
        self.portfolio_value = float(self.initial_cash)
        # allocations réinitialisées dans __init__
        return self._get_observation(), {}

    def step(self, action: np.ndarray):
        """
        Exécute un pas de simulation :
            1. Slice et softmax de l’action sur les N tickers actifs
            2. Calcul du reward basé sur la variation du portefeuille
            3. Mise à jour des allocations
            4. Gestion de la terminaison (fin période ou capital < min_value)
            5. Renvoyé : obs, reward, terminated, truncated, infos

        Args:
            action (np.ndarray): vecteur d’action modèle RL
        Returns:
            (obs, reward, terminated, truncated, infos)
        """
        # 1) slice + softmax
        action = np.asarray(action, dtype=np.float32)[: self.n_tickers]
        exp_a = np.exp(action - np.max(action))
        new_alloc = exp_a / (exp_a.sum() + 1e-8)

        # 2) Calcul du reward (variation portefeuille)
        reward = 0.0
        if self.current_day > 0:
            prev = self.prices[self.current_day - 1]
            curr = self.prices[self.current_day]
            returns = (curr - prev) / (prev + 1e-8)
            returns = np.nan_to_num(returns, nan=0.0, posinf=1.0, neginf=-1.0)
            port_ret = float(np.dot(self.allocations, returns))
            reward = port_ret * self.portfolio_value
            self.portfolio_value += reward

        # 3) Mise à jour de l’allocation
        self.allocations = new_alloc
        self.current_day += 1

        # 4) Vérification de terminaison : fin du dataset ou capital < cap_floor
        terminated = (self.current_day >= self.n_days) or (self.portfolio_value < self.min_value)
        truncated  = False

        # 5) Observation suivante ou zéro si terminé
        obs = self._get_observation() if not terminated else np.zeros(
            self.observation_space.shape, dtype=np.float32
        )
        info = {"portfolio_value": self.portfolio_value}

        # 6) Retour format Gymnasium (obs, reward, terminated, truncated, info)
        return obs, reward, terminated, truncated, info

    def render(self, mode="human"):
        """
        Affichage console basique de la valeur du portefeuille courant.
        """
        print(f"Day {self.current_day}/{self.n_days} — Value €{self.portfolio_value:.2f}")

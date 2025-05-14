"""
PortfolioEnv — Environnement Gymnasium pour Finovera
====================================================
• Compatible SB3 v2.x (Gymnasium API).
• Nombre de tickers dynamique + allocation initiale.
• Observation PAD/TRIM à TARGET_DIM = 449.
• Action_space fixe ACTION_DIM = 112, slicing en step().
• Nouveau paramètre cap_floor pour la préservation du capital.
"""

from __future__ import annotations
import numpy as np
import gymnasium as gym
from gymnasium import spaces

class PortfolioEnv(gym.Env):
    TARGET_DIM = 449     # dimensions observations pour le modèle global
    ACTION_DIM = 112     # dimensions action pour le modèle global

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
        cap_floor: float = 0.90,   # ← nouveau paramètre (0.5–1.0)
    ):
        super().__init__()

        # ─── Données ───────────────────────────────────────────────
        self.prices     = prices
        self.volumes    = volumes
        self.sentiments = sentiments

        self.n_days, self.n_tickers = prices.shape
        self.tickers = tickers or [f"T{i}" for i in range(self.n_tickers)]

        # ─── Paramètres financiers ─────────────────────────────────
        self.initial_cash   = initial_cash
        self.max_allocation = max_allocation
        self.use_volume     = use_volume and (volumes is not None)
        self.use_sentiment  = use_sentiment and (sentiments is not None)

        # ─── Paramètres de préservation du capital ────────────────
        self.cap_floor = cap_floor
        # valeur plancher absolue en euros
        self.min_value = self.initial_cash * self.cap_floor

        # ─── État initial ─────────────────────────────────────────
        self.current_day    = 0
        if initial_allocation is not None:
            assert len(initial_allocation) == self.n_tickers
            self.allocations = initial_allocation.astype(np.float32)
        else:
            # allocation uniforme au départ
            self.allocations = np.ones(self.n_tickers, dtype=np.float32) / self.n_tickers

        self.portfolio_value = float(self.initial_cash)

        # ─── Espaces Gym ──────────────────────────────────────────
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
        # … (inchangé ; nettoie NaN, pad/trim à TARGET_DIM) …
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

        # pad / trim
        if obs.size < self.TARGET_DIM:
            obs = np.pad(obs, (0, self.TARGET_DIM-obs.size), constant_values=0.0)
        else:
            obs = obs[: self.TARGET_DIM]

        return obs

    def reset(self, *, seed: int | None = None, options: dict | None = None):
        super().reset(seed=seed)
        self.current_day    = 0
        self.portfolio_value = float(self.initial_cash)
        # allocations réinitialisées dans __init__
        return self._get_observation(), {}

    def step(self, action: np.ndarray):
        # 1) slice + softmax
        action = np.asarray(action, dtype=np.float32)[: self.n_tickers]
        exp_a = np.exp(action - np.max(action))
        new_alloc = exp_a / (exp_a.sum() + 1e-8)

        # 2) calcul du reward
        reward = 0.0
        if self.current_day > 0:
            prev = self.prices[self.current_day - 1]
            curr = self.prices[self.current_day]
            returns = (curr - prev) / (prev + 1e-8)
            returns = np.nan_to_num(returns, nan=0.0, posinf=1.0, neginf=-1.0)
            port_ret = float(np.dot(self.allocations, returns))
            reward = port_ret * self.portfolio_value
            self.portfolio_value += reward

        # 3) mise à jour
        self.allocations = new_alloc
        self.current_day += 1

        # 4) flags termination selon min_value
        terminated = (self.current_day >= self.n_days) or (self.portfolio_value < self.min_value)
        truncated  = False

        # 5) prochaine observation
        obs = self._get_observation() if not terminated else np.zeros(
            self.observation_space.shape, dtype=np.float32
        )
        info = {"portfolio_value": self.portfolio_value}

        # 6) retour 5-tuple Gymnasium
        return obs, reward, terminated, truncated, info

    def render(self, mode="human"):
        print(f"Day {self.current_day}/{self.n_days} — Value €{self.portfolio_value:.2f}")

import numpy as np
import gym
from gym import spaces

class PortfolioEnv(gym.Env):
    def __init__(
        self,
        prices,
        volumes=None,
        sentiments=None,
        lstm_predictions=None,
        tickers=None,
        initial_cash=100000,
        max_allocation=1.0,
        use_sentiment=True,
        use_volume=True,
        use_macro=False,
        use_lstm_pred=True
    ):
        super().__init__()
        self.prices = prices
        self.volumes = volumes
        self.sentiments = sentiments
        self.lstm_predictions = lstm_predictions
        self.tickers = list(tickers) if tickers is not None else [f"T{i}" for i in range(prices.shape[1])]
        self.n_tickers = len(self.tickers)
        self.n_days = prices.shape[0]

        self.initial_cash = initial_cash
        self.max_allocation = max_allocation
        self.use_sentiment = use_sentiment
        self.use_volume = use_volume
        self.use_macro = use_macro
        self.use_lstm_pred = use_lstm_pred

        self.current_day = 0
        self.allocations = np.zeros(self.n_tickers, dtype=np.float32)
        self.portfolio_value = float(self.initial_cash)

        obs_dim = 1 + self.n_tickers
        if self.use_volume and self.volumes is not None:
            obs_dim += self.n_tickers
        if self.use_sentiment and self.sentiments is not None:
            obs_dim += self.n_tickers
        if self.use_lstm_pred and self.lstm_predictions is not None:
            obs_dim += self.n_tickers

        self.observation_space = spaces.Box(low=0.0, high=1.0, shape=(obs_dim,), dtype=np.float32)
        self.action_space = spaces.Box(low=-1.0, high=1.0, shape=(self.n_tickers,), dtype=np.float32)

    def _get_observation(self):
        day_norm = self.current_day / (self.n_days - 1)
        obs = [day_norm]
        obs.extend(self.allocations)

        if self.use_volume and self.volumes is not None:
            volume_today = self.volumes[self.current_day]
            max_volume = np.max(self.volumes, axis=0)
            volume_norm = np.where(max_volume > 0, volume_today / max_volume, 0)
            obs.extend(volume_norm)

        if self.use_sentiment and self.sentiments is not None:
            sentiment_today = self.sentiments[self.current_day]
            sentiment_scaled = (sentiment_today + 1) / 2
            obs.extend(sentiment_scaled)

        if self.use_lstm_pred and self.lstm_predictions is not None:
            lstm_today = self.lstm_predictions[self.current_day]
            obs.extend(lstm_today)

        obs = np.array(obs, dtype=np.float32)
        obs = np.nan_to_num(obs, nan=0.0, posinf=1.0, neginf=-1.0)

        if np.isnan(obs).any():
            print(f"🚨 NaN dans observation à step {self.current_day} → {obs}")
            obs = np.zeros_like(obs, dtype=np.float32)

        return obs

    def reset(self):
        self.current_day = 0
        self.allocations = np.zeros(self.n_tickers, dtype=np.float32)
        self.portfolio_value = float(self.initial_cash)
        return self._get_observation()

    def step(self, action):
        exp_a = np.exp(action)
        new_alloc = exp_a / np.sum(exp_a)

        reward = 0.0
        if self.current_day > 0:
            prev_prices = self.prices[self.current_day - 1]
            curr_prices = self.prices[self.current_day]
            returns = (curr_prices - prev_prices) / (prev_prices + 1e-8)
            returns = np.nan_to_num(returns, nan=0.0, posinf=1.0, neginf=-1.0)
            portfolio_return = np.sum(self.allocations * returns)
            reward = portfolio_return * self.portfolio_value
            self.portfolio_value += reward

        self.allocations = new_alloc
        self.current_day += 1
        done = self.current_day >= self.n_days

        if done:
            obs = np.zeros(self.observation_space.shape, dtype=np.float32)
        else:
            obs = self._get_observation()

        if np.isnan(obs).any():
            print(f"🚨 NaN dans obs (post-step) → step {self.current_day}")
            obs = np.zeros_like(obs, dtype=np.float32)

        return obs, reward, done, {}

    def render(self, mode='human'):
        print(f"Step {self.current_day} - Portfolio Value: {self.portfolio_value:.2f}")
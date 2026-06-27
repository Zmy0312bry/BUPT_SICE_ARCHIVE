"""Q-learning agent with epsilon-greedy exploration using PyTorch tensors."""

import torch

from .config import GAMMA, LR


class QLearningAgent:
    """Tabular Q-learning agent backed by a torch.Tensor Q-table."""

    def __init__(self, n_states: int, n_actions: int) -> None:
        """Initialize Q-table with zeros.

        Args:
            n_states: Number of discrete states.
            n_actions: Number of discrete actions.
        """
        self.q_table = torch.zeros(n_states, n_actions)

    def select_action(self, state: int, epsilon: float) -> int:
        """Select action via epsilon-greedy policy (ties broken randomly).

        Args:
            state: Current state index.
            epsilon: Exploration probability.

        Returns:
            Selected action index.
        """
        if torch.rand(1).item() > epsilon:
            row = self.q_table[state]
            max_val = torch.max(row)
            candidates = torch.where(row == max_val)[0]
            idx = torch.randint(candidates.shape[0], (1,)).item()
            return int(candidates[idx])
        return torch.randint(self.q_table.shape[1], (1,)).item()

    def update(
        self, state: int, action: int, reward: float, next_state: int
    ) -> None:
        """Perform Q-learning Bellman update.

        Args:
            state: Previous state index.
            action: Taken action index.
            reward: Observed immediate reward.
            next_state: Resulting state index.
        """
        td_target = reward + GAMMA * torch.max(self.q_table[next_state])
        self.q_table[state, action] += LR * (td_target - self.q_table[state, action])

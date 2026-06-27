"""MEC environment: task arrivals, rate transitions, reward computation."""

import math

import torch

from .config import BETA, F, I, J, N_RATES, P, Q_MAX, RATES, T_AV, THETA


class MECEnvironment:
    """Stateless MEC environment providing transitions and rewards."""

    @staticmethod
    def state_index(queue: int, rate_idx: int) -> int:
        """Map (queue, rate_idx) to flat state index."""
        return queue * N_RATES + rate_idx

    @staticmethod
    def decode_state(state: int) -> tuple[int, int]:
        """Decode flat state index into (queue, rate_idx)."""
        return state // N_RATES, state % N_RATES

    @staticmethod
    def sample_arrival() -> int:
        """Sample task arrivals: 0 or 8 with equal probability."""
        return 0 if torch.rand(1).item() < 0.5 else 8

    @staticmethod
    def sample_rate_idx() -> int:
        """Sample next transmission rate index from Markov chain."""
        r = torch.rand(1).item()
        if r < 0.25:
            return 0
        if r < 0.75:
            return 1
        return 2

    @staticmethod
    def clamp_queue(q: int) -> int:
        """Clamp queue length to [0, Q_MAX]."""
        return min(q, Q_MAX)

    @staticmethod
    def offload_reward(q: int, rate: float, a_loc: int, a_off: int) -> float:
        """Compute immediate reward for offload action (local + offload)."""
        total = a_loc + a_off
        if total == 0:
            return -q / T_AV
        utility = THETA * math.log(1 + total)
        energy = BETA * F * F * J * a_loc + P * I * a_off / rate
        penalty = q / T_AV + (J * a_loc / F + I * a_off / rate) / total
        return utility - energy - penalty

    @staticmethod
    def local_reward(q: int, a_loc: int) -> float:
        """Compute immediate reward for local-only action."""
        if a_loc == 0:
            return -q / T_AV
        utility = THETA * math.log(1 + a_loc)
        energy = BETA * F * F * J * a_loc
        penalty = q / T_AV + J / F
        return utility - energy - penalty

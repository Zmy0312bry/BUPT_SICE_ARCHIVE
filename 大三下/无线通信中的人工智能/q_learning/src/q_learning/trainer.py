"""Training loop for MEC Q-learning task offloading."""

import csv
from pathlib import Path

from .agent import QLearningAgent
from .config import (
    ACTIONS,
    ACTIONS_LOCAL,
    ACTIONS_OFFLOAD,
    EPSILON,
    N_QUEUE,
    N_STATES,
    RATES,
    SLOT_MAX,
)
from .environment import MECEnvironment


def train(output_dir: str = "output") -> tuple[QLearningAgent, QLearningAgent, QLearningAgent]:
    """Run Q-learning training and save per-slot average rewards to CSV.

    Args:
        output_dir: Directory for output CSV log.

    Returns:
        Trained (offload+local, offload_only, local_only) agents.
    """
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    env = MECEnvironment()
    agent_off = QLearningAgent(N_STATES, len(ACTIONS))
    agent_pure = QLearningAgent(N_STATES, len(ACTIONS_OFFLOAD))
    agent_loc = QLearningAgent(N_QUEUE, len(ACTIONS_LOCAL))

    q_off, ri_off = 0, 2
    q_pure, ri_pure = 0, 2
    q_loc = 0
    s_off = env.state_index(q_off, ri_off)
    s_pure = env.state_index(q_pure, ri_pure)
    s_loc = q_loc

    cum_off, cum_pure, cum_loc = 0.0, 0.0, 0.0
    logs: list[tuple[int, float, float, float]] = []

    for slot in range(1, SLOT_MAX + 1):
        # --- Offload + Local ---
        a_idx = agent_off.select_action(s_off, EPSILON)
        a_loc, a_off = ACTIONS[a_idx]
        total = a_loc + a_off
        if total <= q_off:
            r_off = env.offload_reward(q_off, RATES[ri_off], a_loc, a_off)
        else:
            a_idx, a_loc, a_off, total = 0, 0, 0, 0
            r_off = env.offload_reward(q_off, RATES[ri_off], 0, 0)
        cum_off += r_off
        dao = env.sample_arrival(); ri_off = env.sample_rate_idx()
        new_q = env.clamp_queue(q_off + dao - total)
        next_s = env.state_index(new_q, ri_off)
        agent_off.update(s_off, a_idx, r_off, next_s)
        s_off, q_off = next_s, new_q

        # --- Pure Offload ---
        a_idx = agent_pure.select_action(s_pure, EPSILON)
        a_p = ACTIONS_OFFLOAD[a_idx][1]
        if a_p <= q_pure:
            r_pure = env.offload_reward(q_pure, RATES[ri_pure], 0, a_p)
        else:
            a_idx, a_p = 0, 0
            r_pure = env.offload_reward(q_pure, RATES[ri_pure], 0, 0)
        cum_pure += r_pure
        dao = env.sample_arrival(); ri_pure = env.sample_rate_idx()
        new_q = env.clamp_queue(q_pure + dao - a_p)
        next_s = env.state_index(new_q, ri_pure)
        agent_pure.update(s_pure, a_idx, r_pure, next_s)
        s_pure, q_pure = next_s, new_q

        # --- Local Only ---
        a_idx = agent_loc.select_action(s_loc, EPSILON)
        a_loc_val = ACTIONS_LOCAL[a_idx]
        if a_loc_val <= q_loc:
            r_loc = env.local_reward(q_loc, a_loc_val)
        else:
            a_idx, a_loc_val, r_loc = 0, 0, env.local_reward(q_loc, 0)
        cum_loc += r_loc
        new_q = env.clamp_queue(q_loc + env.sample_arrival() - a_loc_val)
        next_s = new_q
        agent_loc.update(s_loc, a_idx, r_loc, next_s)
        s_loc, q_loc = next_s, new_q

        logs.append((slot, cum_off / slot, cum_pure / slot, cum_loc / slot))

    csv_path = Path(output_dir) / "rewards.csv"
    with open(csv_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["slot", "avg_reward_offload", "avg_reward_offload_only",
                         "avg_reward_local"])
        writer.writerows(logs)
    return agent_off, agent_pure, agent_loc

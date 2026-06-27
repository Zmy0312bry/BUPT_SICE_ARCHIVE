"""Entry point for MEC Q-learning task offloading simulation."""

from q_learning.trainer import train
from q_learning.visualizer import (plot_policy, plot_q_heatmap_offload,
                                   plot_q_heatmap_pure, plot_rewards)


def main() -> None:
    """Run training, then generate all visualizations."""
    agent_off, agent_pure, agent_loc = train()
    plot_rewards()
    plot_policy(agent_off, agent_pure, agent_loc)
    plot_q_heatmap_offload(agent_off)
    plot_q_heatmap_pure(agent_pure)


if __name__ == "__main__":
    main()

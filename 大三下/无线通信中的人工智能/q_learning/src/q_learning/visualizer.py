"""Visualization: reward curves, learned policy, Q-table heatmap."""
import csv
from pathlib import Path
import matplotlib.pyplot as plt
import torch
from .agent import QLearningAgent
from .config import ACTIONS, ACTIONS_LOCAL, N_QUEUE, N_RATES, RATES


def plot_rewards(csv_path: str = "output/rewards.csv",
                 output_path: str = "output/rewards.png") -> None:
    """Render average reward curves for all three strategies."""
    slots, off, pure, loc = [], [], [], []
    with open(csv_path) as f:
        for row in csv.DictReader(f):
            slots.append(int(row["slot"]))
            off.append(float(row["avg_reward_offload"]))
            pure.append(float(row["avg_reward_offload_only"]))
            loc.append(float(row["avg_reward_local"]))
    plt.figure(figsize=(10, 6))
    plt.plot(slots, off, label="Offload + Local")
    plt.plot(slots, pure, label="Offload Only")
    plt.plot(slots, loc, label="Local Only")
    plt.xlabel("Slot"); plt.ylabel("Average Reward")
    plt.title("Q-Learning MEC Task Offloading — Average Reward")
    plt.legend(); plt.grid(True); plt.tight_layout()
    p = Path(output_path); p.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(output_path, dpi=150); plt.close()


def plot_policy(agent_off: QLearningAgent, agent_pure: QLearningAgent,
                agent_loc: QLearningAgent,
                output_path: str = "output/policy.png") -> None:
    """Plot greedy policy comparison: 3 strategies x 3 rates."""
    off_lbl = [f"L{a[0]}+O{a[1]}" for a in ACTIONS]
    pure_lbl = [f"O{a[1]}" for a in ACTIONS[:3]]
    loc_lbl = [f"L{a}" for a in ACTIONS_LOCAL]
    qr = list(range(N_QUEUE))
    rt = [f"Rate = {r / 1e7:.0f}e7 bit/s" for r in RATES]
    fig, axes = plt.subplots(3, 3, figsize=(18, 12))
    for ri in range(N_RATES):
        ax = axes[0, ri]
        best = [int(torch.argmax(agent_off.q_table[q * N_RATES + ri])) for q in qr]
        ax.bar(qr, best, color=plt.cm.tab10.colors[ri])
        ax.set_title(rt[ri], fontsize=11, fontweight="bold")
        ax.set_yticks(range(len(ACTIONS))); ax.set_yticklabels(off_lbl, fontsize=5.5)
        if ri == 0:
            ax.set_ylabel("Offload + Local", fontsize=10, fontweight="bold")
        ax = axes[1, ri]
        best = [int(torch.argmax(agent_pure.q_table[q * N_RATES + ri])) for q in qr]
        ax.bar(qr, best, color=plt.cm.Set2.colors[ri])
        ax.set_yticks(range(3)); ax.set_yticklabels(pure_lbl, fontsize=8)
        if ri == 0:
            ax.set_ylabel("Offload Only", fontsize=10, fontweight="bold")
        ax = axes[2, ri]
        best = [int(torch.argmax(agent_loc.q_table[q])) for q in qr]
        ax.bar(qr, best, color="gray"); ax.set_xlabel("Queue")
        ax.set_yticks(range(len(ACTIONS_LOCAL)))
        ax.set_yticklabels(loc_lbl, fontsize=8)
        if ri == 0:
            ax.set_ylabel("Local Only", fontsize=10, fontweight="bold")
    fig.suptitle("Learned Greedy Policy Comparison", fontsize=14, y=0.97)
    fig.tight_layout(rect=[0.04, 0.01, 1.0, 0.94])
    p = Path(output_path); p.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(output_path, dpi=150); plt.close()


def _plot_heatmap(q_table: torch.Tensor, labels: list[str],
                  title: str, output_path: str) -> None:
    qv = q_table.numpy(); qr = list(range(N_QUEUE))
    vmin, vmax = qv.min(), qv.max()
    fig, axes = plt.subplots(1, 3, figsize=(18, 5))
    for ri in range(N_RATES):
        rows = [q * N_RATES + ri for q in qr]
        im = axes[ri].imshow(qv[rows], aspect="auto", cmap="viridis",
                             vmin=vmin, vmax=vmax)
        axes[ri].set_title(f"Rate = {RATES[ri] / 1e7:.0f} x 10^7 bit/s")
        axes[ri].set_xticks(range(len(labels)))
        axes[ri].set_xticklabels(labels, rotation=45, ha="right", fontsize=7)
        axes[ri].set_yticks(range(N_QUEUE))
        axes[ri].set_xlabel("Action"); axes[ri].set_ylabel("Queue")
    fig.colorbar(im, ax=axes.tolist(), label="Q-value",
                 fraction=0.02, pad=0.08)
    fig.suptitle(title, fontsize=14)
    fig.subplots_adjust(top=0.88, wspace=0.35, right=0.84)
    p = Path(output_path); p.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(output_path, dpi=150); plt.close()

def plot_q_heatmap_offload(agent_off: QLearningAgent,
                           output_path: str = "output/q_heatmap_offload.png") -> None:
    """Q-value heatmap for Offload+Local agent."""
    _plot_heatmap(agent_off.q_table, [f"L{a[0]}+O{a[1]}" for a in ACTIONS],
                  "Q-Table Heatmap — Offload + Local", output_path)


def plot_q_heatmap_pure(agent_pure: QLearningAgent,
                        output_path: str = "output/q_heatmap_pure.png") -> None:
    """Q-value heatmap for Offload Only agent, showing rate differentiation."""
    _plot_heatmap(agent_pure.q_table, [f"O{a[1]}" for a in ACTIONS[:3]],
                  "Q-Table Heatmap — Offload Only", output_path)

"""Hyperparameters and constants for MEC task offloading Q-learning."""

# Task and communication parameters
I = 3e4                            # Task size (bits)
P = 10                             # Transmit power (W)
RATES = [2e7, 10e7, 15e7]          # Available transmission rates (bit/s)
T_AV = 4                           # Average task arrival rate (tasks/slot)

# Device computation parameters
F = 1.0e9                          # Local CPU frequency (cycles/s)
J = 1.3e9                          # CPU cycles required per task (cycles)
BETA = 8e-27                       # Energy consumption coefficient

# Reward parameters
THETA = 30                         # Utility scaling constant
Q_MAX = 16                         # Maximum queue length

# Action spaces: 0/1/2 = number of tasks processed per slot
# Each ACTIONS row is [local_tasks, offloaded_tasks], e.g. [1,1] = 1 local + 1 offload
ACTIONS = [
    [0, 0], [0, 1], [0, 2],
    [1, 0], [1, 1], [1, 2],
    [2, 0], [2, 1], [2, 2],
]
ACTIONS_LOCAL = [0, 1, 2]          # Tasks processed locally (0/1/2)
ACTIONS_OFFLOAD = [[0, 0], [0, 1], [0, 2]]  # Pure offload: only edge server

# Q-learning hyperparameters
EPSILON = 0.09                     # Epsilon-greedy exploration rate
GAMMA = 0.9                        # Discount factor
LR = 0.9                           # Learning rate (alpha)
SLOT_MAX = 30000                   # Maximum training slots

# Derived constants
N_QUEUE = Q_MAX + 1                # Number of discrete queue levels (0..16)
N_RATES = len(RATES)               # Number of discrete rate levels
N_STATES = N_QUEUE * N_RATES       # Total state space size (17 x 3)

# Q-Learning for MEC Task Offloading

基于 Q-learning 的移动边缘计算（MEC）任务卸载决策仿真工具。

## 背景

在移动边缘计算场景中，用户设备面临计算资源受限的问题。设备可将到达的任务在**本地 CPU 处理**或**卸载到边缘服务器**，以在任务处理收益、能量消耗和排队时延之间做权衡。本工具用 tabular Q-learning 学习最优的调度策略。

## 系统模型

### 状态空间
- 队列长度 `q ∈ {0, 1, ..., 16}`（17 个离散等级）
- 信道传输速率 `r ∈ {2×10⁷, 10×10⁷, 15×10⁷} bit/s`（3 个等级）
- 总状态数：17 × 3 = **51**

### 动作空间
- 卸载策略（9 种组合）：本地处理 0/1/2 个任务 × 卸载 0/1/2 个任务
- 纯本地策略（3 种）：处理 0/1/2 个任务（对照基准）

### 奖励函数

每时隙的奖励由三部分组成：

1. **效用**：`θ·ln(1 + a_total)` — 处理任务的收益（对数增长）
2. **能耗成本**：`β·f²·J·a_loc + P·I·a_off / r` — 本地计算能耗 + 卸载传输能耗
3. **排队惩罚**：`q / λ_avg + 服务时间` — 当前队列与时延惩罚

### 转移概率
- 任务到达：每时隙以 50%/50% 概率到达 0 或 8 个任务
- 速率转移：Markov 链，保持在 2e7/10e7/15e7 的概率为 (0.25, 0.5, 0.25)

## 运行

```bash
uv run python main.py
```

首次运行会自动创建虚拟环境并安装依赖（torch, matplotlib）。

### 输出

| 文件 | 说明 |
|---|---|
| `output/rewards.csv` | 每时隙两组策略的平均奖励日志 |
| `output/rewards.png` | 卸载策略 vs 纯本地策略的平均奖励曲线 |

## 项目结构

```
q_learning/
├── main.py                       # 入口
├── AGENTS.md                     # AI 协作指南
├── pyproject.toml                # uv 配置
└── src/q_learning/
    ├── __init__.py
    ├── config.py                 # 超参数与常量
    ├── agent.py                  # ε-greedy Q-learning agent
    ├── environment.py            # MEC 环境（状态、转移、奖励）
    ├── trainer.py                # 训练主循环
    └── visualizer.py             # 结果绘图与 CSV 日志
```

## 预期结果

30000 时隙训练后，卸载策略（Offload + Local）的平均奖励显著优于纯本地策略（Local Only），验证了 MEC 任务卸载在提升系统效率上的收益。

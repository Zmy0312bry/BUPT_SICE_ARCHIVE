import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats
from pathlib import Path

# 设置中文字体
plt.rcParams['font.family'] = 'Maple Mono NF CN'
plt.rcParams['axes.unicode_minus'] = False  # 解决负号显示问题


def read_csv_data(file_path):
    """读取CSV文件并返回DataFrame"""
    df = pd.read_csv(file_path, encoding='utf-8-sig')
    return df


def plot_distribution_for_column(data, column_name, save_path):
    """
    为指定列绘制概率分布图和累积分布图

    Args:
        data: 列数据（numpy数组或pandas Series）
        column_name: 列名称
        save_path: 保存路径
    """
    # 移除NaN值
    clean_data = data.dropna().values

    if len(clean_data) == 0:
        print(f"警告: {column_name} 列没有有效数据，跳过")
        return

    # 计算统计量
    mean_val = np.mean(clean_data)
    std_val = np.std(clean_data, ddof=1)  # 使用样本标准差
    min_val = np.min(clean_data)
    max_val = np.max(clean_data)

    # 创建图形，包含两个子图
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))

    # ========== 左图：概率分布柱状图和正态分布曲线 ==========
    # 绘制直方图
    n, bins, patches = ax1.hist(clean_data, bins=20, density=True,
                                  alpha=0.7, color='skyblue',
                                  edgecolor='black', label='实际样本分布')

    # 绘制正态分布曲线
    x_range = np.linspace(min_val - std_val, max_val + std_val, 100)
    normal_curve = stats.norm.pdf(x_range, mean_val, std_val)
    ax1.plot(x_range, normal_curve, 'r-', linewidth=2, label='标准正态分布曲线')

    # 设置左图标签和标题
    ax1.set_title('功率概率分布图', fontsize=14, fontweight='bold')
    ax1.set_xlabel('功率值(-dBmw)', fontsize=12)
    ax1.set_ylabel('样本数(个)', fontsize=12)
    ax1.legend(loc='upper right', fontsize=10)
    ax1.grid(True, alpha=0.3)

    # ========== 右图：累积分布曲线 ==========
    # 对数据排序
    sorted_data = np.sort(clean_data)
    cumulative = np.arange(1, len(sorted_data) + 1) / len(sorted_data)

    # 绘制累积分布曲线
    ax2.plot(sorted_data, cumulative, 'b-', linewidth=2)
    ax2.set_title('累积概率分布', fontsize=14, fontweight='bold')
    ax2.set_xlabel('功率值(-dBmw)', fontsize=12)
    ax2.set_ylabel('累积概率', fontsize=12)
    ax2.grid(True, alpha=0.3)

    # 在累积分布图上标注统计信息
    text_y_start = 0.95
    text_x = min_val + (max_val - min_val) * 0.02

    stats_text = f'最大值: {max_val:.2f}\n'
    stats_text += f'最小值: {min_val:.2f}\n'
    stats_text += f'均值: {mean_val:.2f}\n'
    stats_text += f'标准差: {std_val:.2f}'

    ax2.text(text_x, text_y_start, stats_text,
             transform=ax2.transData,
             verticalalignment='top',
             bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.8),
             fontsize=10)

    # 标注特殊点
    # 最小值
    ax2.plot(min_val, 0, 'go', markersize=8, label=f'最小值: {min_val:.2f}')
    # 最大值
    ax2.plot(max_val, 1, 'ro', markersize=8, label=f'最大值: {max_val:.2f}')
    # 均值对应的累积概率
    mean_cumulative = np.searchsorted(sorted_data, mean_val) / len(sorted_data)
    ax2.plot(mean_val, mean_cumulative, 'mo', markersize=8,
             label=f'均值: {mean_val:.2f}')

    ax2.legend(loc='lower right', fontsize=9)

    # 调整布局并保存
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.close()

    print(f"已保存图表: {save_path}")
    print(f"  - 样本数: {len(clean_data)}")
    print(f"  - 均值: {mean_val:.2f}, 标准差: {std_val:.2f}")
    print(f"  - 最小值: {min_val:.2f}, 最大值: {max_val:.2f}\n")


def main():
    print("开始处理数据...\n")

    # 读取CSV文件
    csv_file = 'data.csv'
    df = read_csv_data(csv_file)

    # 创建assets目录（如果不存在）
    assets_dir = Path('assets')
    assets_dir.mkdir(exist_ok=True)

    # 遍历每一列，生成图表
    for column in df.columns:
        print(f"正在处理列: {column}")

        # 获取列数据
        column_data = df[column]

        # 生成安全的文件名（替换特殊字符）
        safe_filename = column.replace('/', '_').replace('\\', '_')
        save_path = assets_dir / f'{safe_filename}.png'

        # 绘制图表
        plot_distribution_for_column(column_data, column, save_path)

    print("所有图表已生成完成！")


if __name__ == "__main__":
    main()

import pandas as pd
from math import pi
import matplotlib.pyplot as plt

def calculate_B_and_R(csv_file, n = 24000, u = 4*pi*1e-7, voltage=4):
    # 读取 CSV 文件
    data = pd.read_csv(csv_file).sort_values(by='励磁电流')
    # print(data)
    # 假设 CSV 文件的第一列是励磁电流，第二列是磁阻电流
    excitation_current = data.iloc[:, 0]
    magnetoresistance_current = data.iloc[:, 1]

    # 计算磁感应强度 B
    B = u * n * excitation_current * 10

    # 计算磁阻 R
    R = voltage / magnetoresistance_current * 1000

    return B, R

# 示例使用
def test1():
    B1, R1 = calculate_B_and_R('./number_up.csv')

    B2, R2 = calculate_B_and_R('./number_low.csv')

    plt.plot(B1, R1,'o-', label='增大磁场')
    plt.plot(B2, R2,'x-', label='减小磁场')
    plt.legend()
    plt.xlabel('B(Gs)')
    plt.ylabel('R(Ω)')
    plt.title('GMR的磁阻特性R-B曲线')
    plt.size = (12, 6)
    plt.rcParams['font.sans-serif'] = ['SimHei']  # 指定默认字体
    plt.rcParams['axes.unicode_minus'] = False  # 解决保存图像时负号'-'显示为方块的问题
    plt.show()

def calcualte_U_and_B(csv_file, n = 24000, u = 4*pi*1e-7):
    # 读取 CSV 文件
    data = pd.read_csv(csv_file).sort_values(by='励磁电流(mA)')
    # print(data)
    # 假设 CSV 文件的第一列是励磁电流，第二列是磁阻电流
    excitation_current = data.iloc[:, 0]
    output_votage = data.iloc[:, 1]
    # print(output_votage)
    # 计算磁感应强度 B
    B = u * n * excitation_current * 10

    # 计算磁阻 R
    U = output_votage

    return U, B
def test2():
    U, B = calcualte_U_and_B('./R_to_C.csv')
    plt.plot(B, U,'o-', label='增大磁场')
    plt.legend()
    plt.xlabel('B(Gs)')
    plt.ylabel('U(mV)')
    plt.title('磁电转换U-B特性曲线')
    plt.size = (12, 6)
    plt.rcParams['font.sans-serif'] = ['SimHei']  # 指定默认字体
    plt.rcParams['axes.unicode_minus'] = False  # 解决保存图像时负号'-'显示为方块的问题
    plt.show()

def calculate_switch(csv_file,n = 24000, u = 4*pi*1e-7):
    data = pd.read_csv(csv_file)
    # print(data)
    U = data.iloc[:, 0]
    B1 = data.iloc[:, 1]
    B2 = data.iloc[:, 2]
    U_max = U.max()
    U_min = U.min()
    # print(U_max)
    # print(U_min)
    B1 = u * n * B1 * 10
    B2 = u * n * B2 * 10
    print(B1)
    print(B2)

    def calculate_y(B, B1, B2, U_min, U_max):
        y = []
        for b in B:
            if B1 <= b <= B2:
                y.append(U_min)
            else:
                y.append(U_max)
        return y
    import numpy as np
    B = np.linspace(B1.min()-1, B2.max()+1, 100)
    B.sort()
    y1 = calculate_y(B, B1.min(), B1.max(), U_min, U_max)
    y2 = calculate_y(B, B2.min(), B2.max(), U_min, U_max)

    plt.plot(B, y1, '-', label='减小磁场')
    plt.plot(B, y2, '-', label='增大磁场')
    plt.legend()
    plt.xlabel('B(Gs)')
    plt.ylabel('U(V)')
    plt.title('磁电转换U-B特性曲线')
    plt.size = (12, 6)
    plt.rcParams['font.sans-serif'] = ['SimHei']  # 指定默认字体
    plt.rcParams['axes.unicode_minus'] = False  # 解决保存图像时负号'-'显示为方块的问题
    plt.show()
def test3():
    calculate_switch('./on_off.csv')

def calculate_theta(csv_file):
    data = pd.read_csv(csv_file)

    theta = data.iloc[:, 0]
    votage = data.iloc[:, 1]
    import numpy as np
    from scipy.interpolate import make_interp_spline
    theta_new = np.linspace(theta.min(), theta.max(), 300)  # 生成300个点
    spl = make_interp_spline(theta, votage, k=3)  # 使用三次样条插值
    votage_smooth = spl(theta_new)
    plt.plot(theta_new, votage_smooth, label='磁场角度变化')
    plt.scatter(theta, votage, color='red', marker='o')  # 原始数据点
    plt.legend()
    plt.xlabel('θ(°)')
    plt.ylabel('U(mV)')
    plt.title('磁电转换U-θ特性曲线')
    plt.size = (12, 6)
    plt.rcParams['font.sans-serif'] = ['SimHei']  # 指定默认字体
    plt.rcParams['axes.unicode_minus'] = False  # 解决保存图像时负号'-'显示为方块的问题
    plt.grid(True)
    plt.show()
def test4():
    calculate_theta('./theta_U.csv')
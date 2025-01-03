import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit

class VoltageResistorAnalysis:
    def __init__(self, csv_file=None):
        self.csv_file = csv_file
        self.data = None
        if csv_file:
            self.load_data()

    def load_data(self):
        if self.csv_file:
            with open(self.csv_file, 'r') as file:
                first_line = file.readline()
                if any(char.isalpha() for char in first_line):
                    self.data = pd.read_csv(self.csv_file, skiprows=1,usecols=[0,1], header=None).sort_values(by=0)
                else:
                    self.data = pd.read_csv(self.csv_file, header=None).sort_values(by=0)
            self.data.columns = ['U', 'R']
            print("数据加载完成")
        else:
            raise FileNotFoundError("没有提供CSV文件")

    def calculate_current(self):
        if self.data is not None:
            self.data['I'] = self.data['U'] / self.data['R']
            self.data.to_csv(self.csv_file, index=False)
            print("电流计算完成")
        else:
            raise ValueError("数据未加载")

    def fitting(self,guess_points):
        if self.data is not None:
            # 提取电压和电流
            u = self.data['U']
            i = self.data['I']
            def absolute_value_model(x, a1, a2,c,point1,point2):
                return a1 * np.abs(x - point1) + a2 * np.abs(x - point2) + c
            
            params, pcov = curve_fit(absolute_value_model, u, i, 
                                     p0=[0.0001, 0.0004,0,guess_points[0],guess_points[1]],
                                   # bounds = ([-np.inf, -np.inf, -np.inf, -2.2, -np.inf], [np.inf, np.inf, np.inf, 0, np.inf]))
                                   )

            print("间断点：",params[-2:])
            if hasattr(self, 'function'):
                del self.function
                print("删除原有拟合函数")
            self.function = lambda x: absolute_value_model(x, *params)
        
        else:
            raise ValueError("数据未加载")

    def choose_point(self,x1,x2):
        if self.data is not None:
            u = self.data['U']
            i = self.data['I']
            # 获取 x1 和 x2 对应的 y 值
            y1 = i[u == x1].values[0] if not i[u == x1].empty else None
            y2 = i[u == x2].values[0] if not i[u == x2].empty else None

            # 获取第一个和最后一个 x 和 y 值
            first_x = u.iloc[0]
            first_y = i.iloc[0]
            last_x = u.iloc[-1]
            last_y = i.iloc[-1]

            print(f"x1: {x1}, y1: {y1}")
            print(f"x2: {x2}, y2: {y2}")
            print(f"第一个点: x: {first_x}, y: {first_y}")
            print(f"最后一个点: x: {last_x}, y: {last_y}")
            print(f"k1 = {(y1-first_y)/(x1-first_x)}")
            print(f"k2 = {(y2-y1)/(x2-x1)}")
            print(f"k3 = {(last_y-y2)/(last_x-x2)}")
            print(f"function: y = {first_y + (-first_x)*(y1-first_y)/(x1-first_x)} + {(y1-first_y)/(x1-first_x)}x")
            print(f"function: y = {y1 + (-x1)*(y2-y1)/(x2-x1)} + {(y2-y1)/(x2-x1)}x")
            print(f"function: y = {y2 + (-x2)*(last_y-y2)/(last_x-x2)} + {(last_y-y2)/(last_x-x2)}x")
            def liner_model(x):
                result = np.zeros_like(x)
                mask1 = x < x1
                mask2 = (x >= x1) & (x < x2)
                mask3 = x >= x2

                result[mask1] = (y1 - first_y) * (x[mask1] - first_x) / (x1 - first_x) + first_y
                result[mask2] = y1 + (y2 - y1) * (x[mask2] - x1) / (x2 - x1)
                result[mask3] = y2 + (last_y - y2) * (x[mask3] - x2) / (last_x - x2)

                return result

            if hasattr(self, 'function'):
                del self.function
                print("删除原有选择点函数")
            self.function = liner_model
                
        else:
            raise ValueError("数据未加载")
    
    def show_pic(self, show_fitted=True, show_points=True):
        if self.data is not None:
            u = self.data['U']
            i = self.data['I']

            plt.figure(figsize=(10, 6))
            if show_points:
                plt.plot(u, i, 'o', label='原始数据点')

            if show_fitted:
                u_fit = np.linspace(u.min(), u.max(), 1000)
                i_fit = self.function(u_fit)
                plt.plot(u_fit, i_fit, label='拟合直线')

            plt.xlabel('电压(U)')
            plt.ylabel('电流(I)')
            plt.title('I-U曲线及拟合直线')
            plt.legend()
            plt.rcParams['font.sans-serif'] = ['SimHei']  # 指定默认字体
            plt.rcParams['axes.unicode_minus'] = False  # 解决保存图像时负号'-'显示为方块的问题
            plt.grid(True)
            plt.show()
        else:
            raise ValueError("数据未加载")

if __name__ == '__main__':
    # analysis = VoltageResistorAnalysis('123.csv')
    # # analysis.load_data()
    # analysis.calculate_current()
    # # analysis.fitting([2, 10.23])
    # analysis.choose_point(1.83,10.23)
    # #analysis.show_pic(show_fitted=True, show_points=True)
    analysis  =VoltageResistorAnalysis("111.csv")
    analysis.calculate_current()

    #analysis.fitting([-10,-2])
    analysis.choose_point(-10.069,-1.769)
    analysis.show_pic(show_fitted=True, show_points=True)
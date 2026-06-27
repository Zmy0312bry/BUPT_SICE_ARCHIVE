# 导入库函数
import os
import codecs
import numpy as np
import matplotlib.pyplot as plt 
import seaborn as sns
import copy
import tf_utils.DataPreProcess

# 工具列表
########################################################
# 1. DecodeData 解归一化
# 2. ShowPrediction 预测结果可视化
# 3. HotMap 绘制热力图（预测结果空间可视化）
# 4. CalculateMAE 计算MAE指标
# 5. CalculateMSE 计算MSE指标
# 6. CalculateRMSE 计算RMSE指标
# 7. CalculateR2score 计算R2分数指标
# 8. show_line_chart 预测结果可视化（示例）
########################################################

def DecodeData(data_path, max_min_path):
    data = np.array(DataPreProcess.GetData(data_path))
    # 解归一化
    max_min_str = []
    with codecs.open(max_min_path, 'r', 'utf-8') as r:
        max_min_str = [line for line in r.readlines()]
    max_min = []
    for i in range(len(max_min_str)):
        max_min.append([float(value) for value in max_min_str[i].split()])

    # 转置后为2*24000，即每个城市的最大值和最小值 
    max_min = np.array(max_min).T
    data = data*(max_min[0]-max_min[1])+max_min[1]
    return data


def LSTM_DecodeData(all_data1, max_value, min_value):
    all_data = copy.deepcopy(all_data1)
    # 对数据进行解归一化处理
    all_data = all_data * (max_value - min_value) + min_value
    return all_data

def ShowPrediction(loc_id, result_dict, label):
    index = np.arange(label.shape[0])
    plt.figure(figsize=(15,7))
    plt.plot(index, np.array(label[:, loc_id]),color='b', label='真实值')
    keys = result_dict.keys()
    for key in keys:
        plt.plot(index, np.array(result_dict[key][:, loc_id]), label=key)
    # legend设置图例
    plt.rcParams['font.sans-serif']=['SimHei'] #显示中文标签
    plt.rcParams['font.serif'] = ['KaiTi']
    plt.rcParams['axes.unicode_minus'] = False

    date = ['12月8日', '12月9日', '12月10日', '12月11日', '12月12日', '12月13日', '12月14日']
    dt = list(range(len(index)))
    plt.xticks(range(1, len(dt), 24), date, rotation=0, fontsize=15)
    plt.yticks(fontsize=20)
    plt.legend(loc = 'best')
    plt.title("预测值、实际值分布图 ID=%d"%(loc_id),fontsize=20)
    plt.xlabel('时间', fontsize=15)
    plt.ylabel('流量', fontsize=15)
    plt.legend(fontsize=15)
    plt.tight_layout()
    plt.savefig('./results/5-5-9.svg', format='svg')
    plt.show()
    
    
def HotMap(hour, results_dict, label):
    _label = copy.deepcopy(label)
    _results_dict = copy.deepcopy(results_dict)
    hour_label = np.array([_label[i] for i in range(hour, _label.shape[0], 24)])
    hour_label_mean = np.mean(hour_label, axis=0)
    keys = results_dict.keys()
    matrix1 = []
    for i in range(20):
        matrix1.append([hour_label_mean[i * 20 + j] for j in range(20)])
    matrix1 = np.array(matrix1)
    plt.figure(figsize=(5, 5))
    plt.rcParams['font.sans-serif'] = ['SimHei']  # 显示中文标签
    plt.rcParams['font.serif'] = ['KaiTi']
    plt.rcParams['axes.unicode_minus'] = False
    ax1 = sns.heatmap(matrix1, square=True)
    plt.xticks(np.arange(0.5, 20.5, 1), labels=np.arange(1, 21, 1))  # 设置 x 轴刻度
    plt.yticks(np.arange(0.5, 20.5, 1), labels=np.arange(1, 21, 1))  # 设置 y 轴刻度
    ax1.set_title('城市平均真实流量')
    plt.tight_layout()
    plt.subplots_adjust(hspace=0.5)
    plt.savefig('./results/5-5-11_1.svg', format='svg')

    k = 2
    for key in keys:
        title = key
        hour_result = np.array([_results_dict[key][i] for i in range(hour, _results_dict[key].shape[0], 24)])
        hour_result_mean = np.mean(hour_result, axis=0)
        matrix2 = []
        matrix3 = []
        for i in range(20):
            matrix2.append([hour_result_mean[i*20+j] for j in range(20)])

        matrix2 = np.array(matrix2)
        matrix3 = np.abs(matrix1-matrix2)/matrix1
        plt.figure(figsize=(5, 5))
        plt.rcParams['font.sans-serif'] = ['SimHei']  # 显示中文标签
        plt.rcParams['font.serif'] = ['KaiTi']
        plt.rcParams['axes.unicode_minus'] = False
        ax1 = sns.heatmap(matrix2, square=True)
        plt.xticks(np.arange(0.5, 20.5, 1), labels=np.arange(1, 21, 1))  # 设置 x 轴刻度
        plt.yticks(np.arange(0.5, 20.5, 1), labels=np.arange(1, 21, 1))  # 设置 y 轴刻度
        ax1.set_title(title+'预测值')
        plt.tight_layout()
        plt.subplots_adjust(hspace=0.5)
        plt.savefig('./results/5-5-11_%d.svg' %(k), format='svg')
        k = k + 1

        plt.figure(figsize=(5, 5))
        plt.rcParams['font.sans-serif'] = ['SimHei']  # 显示中文标签
        plt.rcParams['font.serif'] = ['KaiTi']
        plt.rcParams['axes.unicode_minus'] = False
        ax1 = sns.heatmap(matrix3, square=True)
        plt.xticks(np.arange(0.5, 20.5, 1), labels=np.arange(1, 21, 1))  # 设置 x 轴刻度
        plt.yticks(np.arange(0.5, 20.5, 1), labels=np.arange(1, 21, 1))  # 设置 y 轴刻度
        ax1.set_title(title+'预测值与真实值误差')
        plt.tight_layout()
        plt.subplots_adjust(hspace=0.5)
        plt.savefig('./results/5-5-11_%d.svg' %(k), format='svg')
        k = k + 1

    plt.show()
def CalculateMSE(data, label):
    res = []
    for i in range(label.shape[1]):
        count = 0
        for j in range(label.shape[0]):
            count = count + pow(abs(data[j][i]-label[j][i]), 2)
        res.append(count/label.shape[0])
    return np.mean(res)\

def CalculateMAE(data, label):
    res = []
    for i in range(label.shape[1]):
        count = 0
        for j in range(label.shape[0]):
            count = count + abs(data[j][i]-label[j][i])
        res.append(count/label.shape[0])
    return np.mean(res)


def CalculateRMSE(data, label):
    res = []
    for i in range(label.shape[1]):
        count = 0
        for j in range(label.shape[0]):
            count = count + pow(abs(data[j][i]-label[j][i]), 2)
        count = np.sqrt(count/label.shape[0])
        res.append(count)
    return np.mean(res)

def CalculateR2score(data, label):
    R2_score = []
    MSE = []
    for i in range(label.shape[1]):
        count = 0
        for j in range(label.shape[0]):
            count = count + pow(abs(data[j][i]-label[j][i]), 2)
        MSE.append(count/label.shape[0])
    VAR = []
    for i in range(label.shape[1]):
        VAR.append(np.var(data[:, i]))
    
    for i in range(len(MSE)):
        R2_score.append(1-(MSE[i]/VAR[i]))
    return np.mean(R2_score)

def show_line_chart(result, label):
    plt.rcParams['font.sans-serif']=['SimHei'] #显示中文标签
    plt.rcParams['font.serif'] = ['KaiTi']
    plt.rcParams['axes.unicode_minus'] = False
    if label.shape[0] == result.shape[0]:
        index = np.arange(label.shape[0])
        plt.figure(figsize=(30,10))
        plt.plot(index, label, c='g', label='Real Value')
        plt.plot(index, result, c='r', label='Predicted Value')
        plt.plot(index, result-label, c='b', label='Deviation')
        #plt.locator_params(axis = 'x', nbins = 8)Real Value
        plt.title("Feature importances", fontsize=30) 
        plt.xticks(fontsize=30)
        plt.yticks(fontsize=30)
#       date = ['星期一','星期二','星期三','星期四','星期五','星期六','星期日']
        dt = list(range(len(label)))
        dt[1] =  'Monday'
        print(dt)
        plt.xticks(range(1,len(dt),24),rotation = 45)
        plt.legend(loc = 'best', fontsize = 20)
        plt.title("预测值，实际值与误差分布图",fontsize=40)
        plt.show()

    else:
        print('Wrong Data!')
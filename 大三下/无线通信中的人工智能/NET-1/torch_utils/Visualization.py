# 导入库函数
import os
import codecs
import numpy as np
import matplotlib.pyplot as plt 
import seaborn as sns
import copy
import torch_utils.DataPreProcess as DataPreProcess

# 工具列表
########################################################
# 1. DecodeData
# 2. ShowPrediction
# 3. HotMap
# 4. CalculateMAE
# 5. CalculateMSE
# 6. CalculateRMSE
# 7. CalculateR2score
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

def ShowPrediction(loc_id, result_dict, label):
    index = np.arange(label.shape[0])
    plt.figure(figsize=(30,10))
    plt.plot(index, np.array(label[:, loc_id]), label='label')
    keys = result_dict.keys()
    for key in keys:
        plt.plot(index, np.array(result_dict[key][:, loc_id]), label=key)
    # legend设置图例
    plt.legend(loc = 'best')
    plt.title("loc %d's(0-399) label values and prediction resaults on testing data" %(loc_id))
    plt.show()
    
    
def HotMap(hour, results_dict, label):
    _label = copy.deepcopy(label)
    _results_dict = copy.deepcopy(results_dict)
    hour_label = np.array([_label[i] for i in range(hour, _label.shape[0], 24)])
    hour_label_mean = np.mean(hour_label, axis=0)
    keys = results_dict.keys()
    for key in keys:
        title = 'The forecast situation of model_%s, which bases on the test dataset' % key
        hour_result = np.array([_results_dict[key][i] for i in range(hour, _results_dict[key].shape[0], 24)])
        hour_result_mean = np.mean(hour_result, axis=0)
        matrix1 = []
        matrix2 = []
        matrix3 = []
        for i in range(20):
            matrix1.append([hour_label_mean[i*20+j] for j in range(20)])
            matrix2.append([hour_result_mean[i*20+j] for j in range(20)])
        matrix1 = np.array(matrix1)
        matrix2 = np.array(matrix2)
        matrix3 = np.abs(matrix1-matrix2)/matrix1    
        
        fig = plt.figure(figsize=(15,5))
        fig.suptitle(title, fontsize=12, color='black')
        plt.subplot(131)
        ax1 = sns.heatmap(matrix1, square=True)
        ax1.set_title('Mean True Values of City')
        plt.subplot(132)
        ax2 = sns.heatmap(matrix2, square=True)
        ax2.set_title('Mean Predicted Values of City')
        plt.subplot(133)
        ax3 = sns.heatmap(matrix3, square=True)
        ax3.set_title('Loss Values of City')
    plt.show()
    


def CalculateMAE(data, label):
    res = []
    for i in range(label.shape[0]):
        count = 0
        for j in range(label.shape[1]):
            count = count + abs(data[i][j]-label[i][j])
        res.append(count/400)
    return np.mean(res)


def CalculateMSE(data, label):
    res = []
    for i in range(label.shape[0]):
        count = 0
        for j in range(label.shape[1]):
            count = count + pow(abs(data[i][j]-label[i][j]), 2)
        res.append(count/400)
    return np.mean(res)

def CalculateRMSE(data, label):
    res = []
    for i in range(label.shape[0]):
        count = 0
        for j in range(label.shape[1]):
            count = count + pow(abs(data[i][j]-label[i][j]), 2)
        count = np.sqrt(count/400)
        res.append(count)
    return np.mean(res)

def CalculateR2score(data, label):
    R2_score = []
    MSE = []
    for i in range(label.shape[0]):
        count = 0
        for j in range(label.shape[1]):
            count = count + pow(abs(data[i][j]-label[i][j]), 2)
        MSE.append(count/400)
    VAR = []
    for i in range(label.shape[0]):
        VAR.append(np.var(data[i]))
    
    for i in range(len(MSE)):
        R2_score.append(1-(MSE[i]/VAR[i]))
    return np.mean(R2_score)
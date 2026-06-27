# 导入库函数
import os
import codecs
import numpy as np
import matplotlib.pyplot as plt 
import copy
import torch_utils.DataPreProcess as DataPreProcess

# 工具列表
########################################################
# 1. MakeDataset
# 2. Generator
# 3. WriteData
########################################################

def MakeDataset(data_path):
    # 开始制作数据
    total_data = DataPreProcess.GetData(data_path)
    day_nums = len(total_data)//400  # 数据的形式转换为（60，400，24）表示60天，400个grid，24小时
    total_data = np.reshape(np.array(total_data), [day_nums, 400, 24])
    print(total_data.shape)
    train, test = [], []
    # 说明一下为什么从第七天开始，因为要计算前三天的数据，以及上一周同一时间的数据，所以要从7开始，不然会造成越界
    for day in range(7, total_data.shape[0]):
        for hour in range(total_data.shape[2]):
            # 制作closeness部分
            closeness = []
            for city in range(total_data.shape[1]):
                temp = []
                if hour < 3:
                    # 注意，要保持顺序的一致，要先添加前一天的数据，在到今天的数据，不能反过来
                    for i in range(0, 3-hour):
                        temp.append(total_data[day-1, city, -(3-hour-i)])
                    for i in range(hour):
                        temp.append(total_data[day, city, i])
                else:
                    for i in range(3):
                        temp.append(total_data[day, city, hour-3+i])
                closeness.append(temp)
            
            # 制作period部分
            period = []
            for city in range(total_data.shape[1]):
                temp = []
                for i in range(3):
                    temp.append(total_data[day-3+i, city, hour])
                period.append(temp)
            
            # 制作trend部分
            trend = total_data[day-7, :, hour]
            
            # 制作label部分
            label = total_data[day, :, hour]
            
            # 矩阵变换
            closeness = np.reshape(np.array(closeness), [20, 20, 3])
            period = np.reshape(np.array(period), [20, 20, 3])
            trend = np.reshape(np.array(trend), [20, 20, 1])
            label = np.reshape(np.array(label), [20, 20, 1])
            
            # 将数据整合
            data = np.c_[closeness, period, trend, label] # 为[20, 20, 8] 
            # print(data.shape)
            
            # 为什么是46，因为要包括40天的数据，从第七天开始，所以是46
            if day <= 46:
                train.append(data)
            else:
                test.append(data)
    
    train = np.array(train) # [960, 20, 20, 8] 40*24 = 960
    test = np.array(test)   # [312, 20, 20, 8] 13*24 = 312
    
    return train, test


def Generator(datas, train_label, steps_per_epoch, batch_size):
    while True:
        for i in range(steps_per_epoch):
            closeness = datas[0][i*batch_size:(i+1)*batch_size]
            period = datas[1][i*batch_size:(i+1)*batch_size]
            trend = datas[2][i*batch_size:(i+1)*batch_size]
            label = train_label[i*batch_size:(i+1)*batch_size]
            yield ({'closeness': closeness, 'period': period, 'trend': trend}, {'output': label})

def WriteData(file_path, data):
    if os.path.exists(file_path):
        print('update: ', file_path)
        os.remove(file_path)
    with codecs.open(file_path, 'a', 'utf-8') as w:
        for i in range(data.shape[0]):
            s = ''
            for j in range(data.shape[1]):   
                s += str(data[i][j]) + ' '
            w.write(s+'\n')
    print('Finish to save data!')
   
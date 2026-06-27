# 导入库函数
import os
import codecs
import numpy as np
import copy

# 工具列表
########################################################
# 1. GetData              : 获取数据
# 2. CalculateMeanValue   : 计算均值
# 3. ProcessMissingValue  : 处理数据内的缺失值
# 4. ProcessAbnormalValue : 处理数据内的异常值
# 5. DataNormalization    : 数据归一化
# 6. SavePreProcessData   : 保存预处理后的数据
########################################################

def GetData(file_path):
    with codecs.open(file_path, 'r', 'utf-8') as read:
        counts1 = [w.strip() for w in read.readlines()]
    
    # 将数据转换为float类型
    data = []
    for i in range(len(counts1)):
        data.append([float(w) for w in counts1[i].split()])
    return data


def CalculateMeanValue(loc, time, city_amount, data, judge_num):
    same_loc_time_datas = []
    # -city_amount*7 表示步长，有400个城市，一周有七天
    # pre表示在这一天之前的日子， later表示在这一天之后的日子
    for pre in range(loc, 0, -city_amount*judge_num):
        if(data[pre][time] != 0):
            same_loc_time_datas.append(data[pre][time])
    for later in range(loc, data.shape[0], city_amount*judge_num):
        if(data[later][time] != 0):
            same_loc_time_datas.append(data[later][time])
    return np.mean(same_loc_time_datas)

def restore_data(data_str):
    # 定义一个data变量用来保存数据
    datas = []
    for i in range(len(data_str)):
        # split()主要是将一行数据按空格分开，得到24个数据(表示每个小时的数据)
        datas.append([float(value) for value in data_str[i].split()])
    return datas

def ProcessMissingValue(data_11, data_12, city_amount, judge_num):
    # 这里是深复制，要注意区分深复制和浅复制的不同
    data_1 = GetData(data_11)
    data_2 = GetData(data_12)

    # 将11月和12月的数据拼在一起，形成24000*24的数据
    data = np.concatenate(data_1 + data_2)
    data = data.reshape(24000, 24)
    # 统计缺失的值
    missing_num = 0
    # all_data.shape[0] = 24000
    # 两个for循环用来遍历整个2维向量
    for i in range(data.shape[0]):
        for j in range(data.shape[1]):
            if(data[i][j] == 0):
                missing_num += 1
                # 将缺失值用同一地区同一天(例如都是星期一)的所有值的和的均值补上
                data[i][j] = CalculateMeanValue(i,j, city_amount, data, judge_num)
    print('There are %d missing datas' %(missing_num))
    return data

def ProcessAbnormalValue(data, city_amount, judge_week_num, judge_day_num):
    all_data = copy.deepcopy(data)
    week_num = judge_week_num // 2
    day_num = judge_day_num // 2
    abnormal_num = 0
    
    for i in range(all_data.shape[0]):
        for j in range(all_data.shape[1]):
            # 定义寻找异常数据的函数
            def find_abnormal(pattern_days, pattern_num):
                pre_same_loc_time_value = []
                for pre in range(i, 0, -city_amount*pattern_days):
                    if(len(pre_same_loc_time_value) == pattern_num+1):
                        break;
                    pre_same_loc_time_value.append(all_data[pre, j])
                later_same_loc_time_value = []
                for later in range(i, all_data.shape[0], city_amount*pattern_days):
                    if(len(later_same_loc_time_value) == pattern_num+1):
                        break;
                    later_same_loc_time_value.append(all_data[later, j])
                
                if(len(pre_same_loc_time_value) < 3 and len(later_same_loc_time_value) == 3):
                    later_add = 3-len(pre_same_loc_time_value)
                    for new_later in range(i+city_amount*pattern_days*(pattern_num+1), i+city_amount*pattern_days*(pattern_num+later_add)+1, city_amount*pattern_days):
                        later_same_loc_time_value.append(all_data[new_later, j])
                if(len(later_same_loc_time_value) < 3 and len(pre_same_loc_time_value) == 3):
                    pre_add = 3-len(later_same_loc_time_value)
                    for new_pre in range(i-city_amount*pattern_days*(pattern_num+1), i-city_amount*pattern_days*(pattern_num+later_add)+1, -city_amount*pattern_days):
                        pre_same_loc_time_value.append(all_data[new_pre, j])
                
                # [1:]表示去除all_data[i,j]本身的数据，取前面和后面的数据
                same_loc_time_value = pre_same_loc_time_value[1:] + later_same_loc_time_value[1:]
                mean = np.mean(same_loc_time_value)
                std = np.std(same_loc_time_value)
                
                # 利用3西格玛准则来判断数据是否异常
                if(all_data[i,j] >= mean+3*std) or (all_data[i,j] <= mean-3*std):
                    return 1, mean
                else:
                    return 0, mean
            week_abnormal, week_mean = find_abnormal(7, week_num)
            day_abnormal, day_mean = find_abnormal(1, day_num)
            if(week_abnormal == 1) and (day_abnormal == 1):
                all_data[i,j] = (week_mean+day_mean)/2
                abnormal_num += 1
    print("There are %d abnormal num" %(abnormal_num))
    return all_data

def DataNormalization(all_data1, file_path, city_amount):
    # 对原数据文件进行处理
    if os.path.exists(file_path):
        print('update: ' + file_path)
        os.remove(file_path)
    
    all_data = copy.deepcopy(all_data1)
    maxs_loc_data, mins_loc_data = [], []
    
    # 将每天的最大最小值存入maxs_loc_data 和mins_loc_data
    for i in range(all_data.shape[0]):
        maxs_loc_data.append(max(all_data[i]))
        mins_loc_data.append(min(all_data[i]))
    
    # 存储每个地区每个时刻的最大最小流量值， 应为400*2的矩阵
    # 每一行第一个对应地区元素为最大值，第二个元素为最小值
    max_min = []
    day_num = all_data.shape[0]//city_amount
    
    for i in range(city_amount):
        max_loc = max([maxs_loc_data[i+j*city_amount] for j in range(day_num)])
        min_loc = min([mins_loc_data[i+j*city_amount] for j in range(day_num)])
        # 保存数据
        with codecs.open(file_path, 'a', 'utf-8') as w:
            w.write(str(max_loc) + ' ' + str(min_loc) + '\n')
        max_min.append([max_loc, min_loc])
    
    # 对数据进行归一化处理
    max_min_all = []
    # 通过循环将矩阵由400*2 扩展为 24000*2
    for i in range(day_num):
        max_min_all += max_min
    max_min_all = np.array(max_min_all)
    
    all_data = (all_data-max_min_all[:,1].reshape([all_data.shape[0], 1]))/(max_min_all[:,0]-max_min_all[:,1]).reshape([all_data.shape[0],1])
    all_data = all_data.reshape([all_data.shape[0]//400, 400, 24])
    return all_data


def LSTM_DataNormalization(all_data1):

    all_data = copy.deepcopy(all_data1)
    max_value = max(all_data)
    min_value = min(all_data)

    # 对数据进行归一化处理
    all_data = (all_data-min_value) / (max_value - min_value)

    return all_data, max_value, min_value


def SavePreProcessData(data, file_path):
    if os.path.exists(file_path):
        print('update ' + file_path)
        os.remove(file_path)
    counts_str = []
    for i in range(data.shape[0]):
        for j in range(data.shape[1]):
            count_str = ''
            for k in range(data.shape[2]):
                if(k!=data.shape[2]-1):
                    count_str += str(data[i][j][k]) + ' '
                else:
                    count_str += str(data[i][j][k])
            counts_str.append(count_str)
    with codecs.open(file_path, 'a', 'utf-8') as w:
        for i in range(len(counts_str)):
            w.write(counts_str[i] + '\n')
    print("success to save PreProcess data!")

def SaveLabelData(data, file_path):
    if os.path.exists(file_path):
        print('update ' + file_path)
        os.remove(file_path)
    counts_str = []
    for i in range(data.shape[0]):
        count_str = ''
        for j in range(data.shape[1]):
            if (j != data.shape[1] - 1):
                count_str += str(data[i][j]) + ' '
            else:
                count_str += str(data[i][j])
        counts_str.append(count_str)
    with codecs.open(file_path, 'a', 'utf-8') as w:
        for i in range(len(counts_str)):
            w.write(counts_str[i] + '\n')
    print("success to save PreProcess data!")

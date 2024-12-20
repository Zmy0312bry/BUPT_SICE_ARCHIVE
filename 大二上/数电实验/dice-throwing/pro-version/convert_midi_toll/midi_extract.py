import tkinter as tk
from tkinter import filedialog
from tkinter import simpledialog, messagebox
import mido
import pandas as pd

CLK_FREQ = 1000000  # 定义时钟频率的变量，这里是1MHz
MAX_CNT = 24  # 最大计数器位数
PLAY_START = 0  # 秒为单位
PLAY_END = 5
SPEED = 1  # 默认为1
# 创建 Tkinter 根窗口
root = tk.Tk()
root.withdraw()  # 隐藏主窗口

# 打开文件选择对话框，选择 MIDI 文件
file_path = filedialog.askopenfilename(
    title="请选择 MIDI 文件",
    filetypes=[("MIDI files", "*.mid;*.midi")]  # 限制选择 MIDI 文件
)


def set_values():
    global PLAY_START, PLAY_END, SPEED

    # 获取用户输入的值，如果没有输入则使用默认值
    start = simpledialog.askfloat("输入播放起点", "请输入播放起点 (秒):", initialvalue=PLAY_START)
    end = simpledialog.askfloat("输入播放终点", "请输入播放终点 (秒):", initialvalue=PLAY_END)
    speed = simpledialog.askfloat("输入播放速度", "请输入播放速度:", initialvalue=SPEED)

    # 检查输入的有效性
    if start is not None and end is not None and speed is not None:
        if speed <= 0:
            messagebox.showerror("输入错误", "播放速度必须大于0！")
            return

        PLAY_START = start
        PLAY_END = end
        SPEED = speed

        # 计算实际播放时长
        duration = (PLAY_END - PLAY_START) / SPEED
        if duration < 0:
            messagebox.showerror("输入错误", "播放起点不能大于播放终点！")
            return

        # 弹出提示框显示播放参数和实际播放时长
        messagebox.showinfo("播放设置结果", f"播放起点: {PLAY_START} 秒\n"
                                            f"播放终点: {PLAY_END} 秒\n"
                                            f"播放速度: {SPEED}\n"
                                            f"实际播放时长: {duration:.2f} 秒")

        # 结束程序
        root.quit()
    else:
        messagebox.showwarning("输入无效", "请确保输入有效值！")


# MIDI 音符到计数的映射公式
def midi_to_cnt(midi_note):
    if midi_note:
        freq = 440 * 2 ** ((midi_note - 69) / 12)  # 转化成频率
        result = CLK_FREQ / (2 * freq)
    else:
        result = 0
    return result


def midi_parse(midi_path):  # 直接返回tempo的文件
    midi_file = mido.MidiFile(midi_path)
    # 提取 set_tempo 消息并存储 tempo 信息
    ppq = midi_file.ticks_per_beat
    tempo_changes = []
    assist = []
    track_num22 = 0
    for track in midi_file.tracks:
        current_time = 0
        for msg in track:
            if msg.type == 'set_tempo':
                current_time += msg.time
                existing_tempo = next((item for item in tempo_changes if item['time'] == current_time), None)
                if existing_tempo:
                    # 如果已有相同 time 的 tempo，则更新该项为最新的 tempo
                    existing_tempo['tempo'] = msg.tempo
                else:
                    # 如果没有相同 time 的 tempo，则添加新的 tempo
                    tempo_changes.append({
                        'time': current_time,
                        'tempo': msg.tempo,
                        'track': track_num22
                    })
                    assist.append((current_time, track_num22))
        track_num22 += 1
    # 将tempo数据转化为有意义的bpm，后续用于计算
    for tempo_change in tempo_changes:
        tempo_change['bpm'] = mido.tempo2bpm(tempo_change['tempo'])

    # 完成tempo的工作,接下来提取音符以及其时间信息
    raw_message = [{
        'type': 'note_off',
        'note': 0,
        'velocity': 0,
        'time': 0,
        'track': 0,
        'tempo_bpm': 10000000000  # 赋值很大就可以了
    }]  # 原始数据
    track_times = 0
    for track in midi_file.tracks:  # 完成音符信息提取，下面将音符的time信息与tempo进行比对，添加一列tempo信息
        current_time = 0
        for msg in track:
            if msg.type == 'note_on' or msg.type == 'note_off':
                current_time += msg.time
                index = 0
                result = [item for item in assist if item[1] == 0]  # 寻找该音轨下的对象
                for i in range(len(result) - 1):
                    if result[i][0] <= current_time < result[i + 1][0]:
                        index = i
                        break
                raw_message.append({
                    'type': msg.type,
                    'note': msg.note,
                    'velocity': msg.velocity,
                    'time': current_time,
                    'track': track_times,
                    'tempo_bpm': tempo_changes[index]['bpm']
                })
        track_times += 1
    raw_df = pd.DataFrame(raw_message)
    print(raw_df)

    # 完成音符信息提取，下面将raw数据直接转化为待用的元组,需要提取信息为频率(计数多少)，time时间(自己计算)
    note_data = []
    track_num1 = 0
    for track in midi_file.tracks:
        id_num = 0
        for msg in track:
            note_data.append({
                'note': midi_to_cnt(raw_message[id_num]['note'] if (raw_message[id_num]['type'] == 'note_on') else 0),
                'time': (60 * CLK_FREQ * raw_message[id_num]['time']) / (raw_message[id_num]['tempo_bpm'] * ppq),  #
                # 系统时钟下的计数个数为单位
                'track': track_num1
            })
            id_num += 1
        track_num1 += 1
    return note_data


# 将 MIDI 文件转换为 Verilog 需要的格式
def generate_verilog_input(midi_file_tmp):
    verilog_code = []
    output_filename = "verilog_code.txt"

    # 遍历 note_data 数组
    for data in midi_file_tmp:
        time = int(data['time']/SPEED)
        note = int(data['note'])
        if time <= (2 ** MAX_CNT):
            # 对于每一个 time 和 note 生成对应的 Verilog case 语句
            verilog_code.append(f"        24'd{time}: begin")
            verilog_code.append(f"            cnt <= cnt+1;  ")
            verilog_code.append(f"            note <= 16'd{note};  ")
            verilog_code.append(f"        end")
        else:
            break

    # 默认情况下设置为 no note
    verilog_code.append("        default: begin")
    verilog_code.append("            cnt <= cnt+1;")
    verilog_code.append("        end")

    # 将生成的 Verilog 代码写入文本文件
    with open(output_filename, 'w') as f:
        for line in verilog_code:
            f.write(line + "\n")

    print(f"Verilog code has been written to {output_filename}")


if file_path:
    print(f"选中的文件路径: {file_path}")
    set_values()
    data_array = midi_parse(file_path)
    generate_verilog_input(data_array)

else:
    print("没有选择文件")

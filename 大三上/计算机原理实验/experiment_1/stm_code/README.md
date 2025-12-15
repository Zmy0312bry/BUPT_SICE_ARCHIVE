# STM32 实验1 - 综合控制实验

## 项目概述
本项目实现了基于STM32F4的多功能控制系统，包括数码管流水灯、交通灯控制和LED流水灯三个子功能，并支持通过按键调节运行频率。

## 硬件配置

### GPIO配置
- **LED1~8**: PF0~PF7 (高电平点亮)
- **交通灯组1 (红黄绿)**: PF8, PF9, PF10
- **交通灯组2 (红黄绿)**: PF11, PF12, PF13
- **74HC595控制 (SI, RCK, SCK)**: PC0, PC1, PC2
- **74HC138控制 (A, B, C)**: PC3, PC4, PC5
- **按钮1 (提高频率)**: PB9 (GPIO_EXTI9)
- **按钮2 (降低频率)**: PB12 (GPIO_EXTI12)

### 定时器配置
- **TIM3**: 定时器中断，频率为10Hz (每100ms触发一次)
  - Prescaler: 8399 (84MHz / 8400 = 10kHz)
  - Period: 999 (10kHz / 1000 = 10Hz)

## 功能实现

### 1. 数码管流水灯
- **实现原理**: 通过74HC595芯片控制8段数码管(a-g + dp)
- **效果**: 同一时刻仅有一个段点亮，按顺序循环点亮各段
- **控制流程**:
  1. 拉低SCK，准备输入数据
  2. 通过SI输入段码数据（从高位到低位）
  3. 拉高SCK，将数据移入74HC595移位寄存器
  4. 重复8次，完成8位数据传输
  5. 拉高RCK，锁存数据到输出端

### 2. 交通灯控制
- **实现原理**: 两组交通灯（每组3个LED：红、黄、绿）交替闪烁
- **效果**: 
  - 状态0: 第一组灯全亮，第二组灯全灭
  - 状态1: 第一组灯全灭，第二组灯全亮
  - 两个状态交替切换

### 3. LED流水灯
- **实现原理**: 8个LED依次点亮后依次熄灭
- **效果**:
  - 模式0: 从LED1到LED8依次点亮
  - 模式1: 从LED1到LED8依次熄灭
  - 两个模式循环切换

### 4. 频率调节
- **按钮1 (PB9)**: 提高频率（减小speed_divider，最小值为2）
- **按钮2 (PB12)**: 降低频率（增大speed_divider，最大值为50）
- **频率范围**: 约0.2Hz ~ 5Hz

## 代码结构

### 全局变量
```c
volatile uint32_t timer_counter = 0;     // 定时器计数器
volatile uint32_t speed_divider = 10;    // 频率控制（初始值10）
volatile uint8_t segment_pos = 0;        // 数码管当前段位置
volatile uint8_t traffic_state = 0;      // 交通灯状态
volatile uint8_t led_mode = 0;           // LED模式（0:点亮 1:熄灭）
volatile uint8_t led_pos = 0;            // LED当前位置
```

### 核心函数

#### HC595_SendByte(uint8_t data)
通过74HC595发送一个字节的段码数据

#### Display_Segment(uint8_t segment_code, uint8_t digit_pos)
显示数码管的特定段，并通过74HC138选择数码管位

#### Update_SegmentLight(void)
更新数码管流水灯状态，移动到下一个段

#### Update_TrafficLight(void)
更新交通灯状态，在两组灯之间切换

#### Update_LEDLight(void)
更新LED流水灯状态，控制点亮/熄灭模式

### 中断处理

#### HAL_TIM_PeriodElapsedCallback()
定时器中断回调函数，根据speed_divider控制更新频率

#### HAL_GPIO_EXTI_Callback()
GPIO外部中断回调函数，处理按键按下事件

## 使用说明

1. **编译与烧录**: `make`+`./flash.sh`(需要安装probe-rs)
2. **运行**: 系统上电后自动开始运行三个功能
3. **调节速度**: 
   - 按下PB9按钮提高运行频率（变快）
   - 按下PB12按钮降低运行频率（变慢）

## 注意事项

1. **USER CODE区域**: 所有代码都在USER CODE BEGIN和USER CODE END标记之间，不会被CubeMX重新生成覆盖
2. **定时器配置**: 在TIM3_Init_2区域重新配置了定时器参数以获得准确的10Hz中断频率
3. **GPIO中断**: 使用上升沿触发，建议在实际应用中添加消抖处理
4. **数码管驱动**: 使用74HC595串行转并行芯片，减少GPIO占用
5. **并发执行**: 三个功能同时运行，共享同一个时基

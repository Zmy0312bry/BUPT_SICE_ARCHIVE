#import "@preview/basic-report:0.3.1": *
#import "@preview/oxdraw:0.1.0": *

#show: it => basic-report(
  doc-category: "计算机原理",
  doc-title: "拓展实验\n基于STM32和FPGA的手写数字识别系统",
  author: "XXX 2023210XXX",
  affiliation: "20232111XX, 信息与通信工程学院, 北京邮电大学",
  logo: image("assets/bupt-logo.jpg", width: 3cm),
  language: "zh",
  heading-font: "Maple Mono NF",
  compact-mode: false,
  // show-outline: false,
  it,
)

= 实验四 拓展实验

== 实验目的

1. 掌握STM32与FPGA的协同工作原理和通信方法
2. 理解神经网络在硬件加速中的实现方式
3. 学习FPGA中串行数据传输和状态机设计
4. 掌握Int8量化神经网络的原理和硬件实现
5. 熟悉STM32的GPIO、UART、Timer等外设的综合应用

== 实验要求

1. 使用STM32F407作为主控制器，通过UART接收手写数字数据
2. 使用FPGA实现MNIST手写数字识别神经网络
3. STM32通过GPIO接口将数据传输至FPGA进行推理
4. 在LCD上显示输入的手写数字图像
5. 在7段数码管上显示识别结果
6. FPGA资源使用需在6,272 LUT以内
7. 系统准确率应达到70%以上

== 实验任务

本实验实现了一个完整的手写数字识别系统，包含以下核心模块：

=== 硬件平台
- *STM32F407*：主控芯片，负责数据接收、LCD显示、数码管控制、FPGA通信
- *FPGA*：硬件加速器，实现神经网络推理运算
- *LCD屏幕*：显示28×28手写数字图像
- *7段数码管*：显示识别结果（0-9）

=== 软件模块
1. *神经网络训练*：使用PyTorch训练MNIST识别模型
2. *模型量化*：Int8量化减少资源占用
3. *Verilog生成*：自动将训练好的模型转换为Verilog硬件描述语言
4. *STM32固件*：实现数据接收、显示控制、FPGA通信
5. *Python上位机*：发送手写数字数据进行测试

== 实验原理

=== 神经网络模型

本系统采用3层全连接神经网络：
- *输入层*：784个节点（28×28像素）
- *隐藏层*：3个神经元（经资源优化后的配置）
- *输出层*：10个神经元（对应数字0-9）

网络结构：`Input(784) → FC1(3) → ReLU → FC2(10) → Argmax`

准确率权衡：
- 3个隐藏神经元：准确率77%，ROM使用2.4KB
- 5个隐藏神经元：准确率85%，ROM使用4.0KB
- 8个隐藏神经元：准确率90%，ROM使用6.4KB

考虑到FPGA资源限制（6,272 LUT），本实验采用3个隐藏神经元的配置。

=== Int8量化原理

为减少硬件资源占用，将浮点权重量化为8位整数：

```text
量化公式：Q = round(W × scale)
其中：
  - W为浮点权重
  - scale为量化比例因子（通常为127）
  - Q为量化后的8位整数（-128到127）

优势：
  - 减少存储空间：从32位浮点降至8位整数
  - 降低运算复杂度：整数乘法代替浮点乘法
  - 准确率损失小：通过微调可恢复至接近原始精度
```

=== FPGA硬件架构

==== 串行MAC架构

采用单个8位×24位MAC（乘加）单元，通过时分复用计算所有神经元：

- *Layer1计算*：3个神经元 × 784个权重 = 2,355次MAC运算
- *Layer2计算*：10个神经元 × 3个权重 = 30次MAC运算
- *Argmax运算*：10次比较找出最大值
- *总时钟周期*：约2,400个时钟周期（在500Hz时钟下约4.8秒）

==== 模块组成

1. *RAM模块*：缓存从STM32串行接收的784位图像数据
2. *MNIST模型模块*：执行神经网络推理运算
3. *Handwriting顶层模块*：协调数据接收和计算流程

=== STM32与FPGA通信协议

==== 引脚定义

```text
STM32输出到FPGA：
  - PC0: FPGA_RST        (复位信号)
  - PC1: FPGA_DATA_IN    (串行数据)
  - PC2: FPGA_CLK        (时钟信号，500Hz)

FPGA输出到STM32：
  - PC3: RESULT_VALID    (结果有效标志)
  - PC4-PC7: DATA_OUT[3:0] (识别结果，4位)
  - PC8: BUSY            (忙碌标志)
```

==== 通信流程

1. *复位阶段*：STM32拉高RST信号，复位FPGA状态机
2. *数据传输阶段*：
   - STM32在CLK下降沿改变DATA_IN数据
   - FPGA在CLK上升沿采样DATA_IN数据
   - 连续传输784个位（每个时钟周期1位）
3. *计算阶段*：FPGA自动开始推理运算，BUSY信号保持高电平
4. *结果输出阶段*：计算完成后，RESULT_VALID拉高，DATA_OUT输出结果

=== 上位机通信协议

STM32通过UART与上位机通信，波特率115200：

1. *握手阶段*：
   - 上位机发送：`Q\r\n`
   - STM32回复：`A\r\n`

2. *数据传输阶段*：
   - 上位机发送：196个十六进制字符 + `\r\n`（98字节压缩数据）
   - 数据格式：每个字节包含8个像素（4位/半字节编码）

3. *显示和处理阶段*：
   - STM32解压数据并在LCD上显示
   - 用户按下按钮后，启动FPGA处理

4. *结果返回阶段*：
   - STM32读取FPGA结果
   - 通过UART返回识别结果

== 实验步骤
=== 实验连线
先按照电路原理图进行连线，如 @figure-1-10 所示。
#figure(
  image("assets/接线图.png"),
  caption: "实验连线图",
) <figure-1-10>

=== 神经网络训练与Verilog生成

1. 进入mnist_model目录
2. 运行训练脚本：
```bash
cd verilog_mnist/mnist_model
uv run python main.py
```

3. 训练过程（约3-5分钟）：
   - 自动下载MNIST数据集
   - 训练12个epoch
   - Int8量化
   - 微调优化
   - 生成`verilog_src/mnist_model.v`

4. 仿真测试：
```bash
cd ../verilog_src
bash test.sh
```

=== FPGA工程配置

1. 将生成的Verilog文件复制到Quartus工程：
   - `mnist_model.v`：神经网络模块
   - `ram.v`：数据缓存模块
   - `handwriting.v`：顶层模块

2. 在Quartus中配置ROM使用Block RAM：
```tcl
set_instance_assignment -name RAMSTYLE "M9K" -to "mnist_model:*|weight_rom"
```

3. 编译并下载到FPGA

=== 程序流程图

==== 系统整体流程

#let mermaid-main = ```
graph LR
    A[系统启动] --> B[外设初始化]
    B --> C{UART握手Q?}
    C -->|是| D[接收图像数据]
    D --> E[LCD显示]
    E --> F{按钮按下?}
    F -->|是| G[FPGA推理]
    G --> H[显示结果]
    H --> C
```
#figure(
    oxdraw(mermaid-main)
)

==== STM32主程序流程

#let mermaid-stm32 = ```
graph LR
    A[程序启动] --> B[HAL初始化]
    B --> C[外设配置]
    C --> D[主循环]
    D --> E{UART数据?}
    E -->|是| F[处理数据]
    E -->|否| G{按钮?}
    F --> G
    G -->|是| H[启动FPGA]
    G -->|否| I{FPGA完成?}
    H --> I
    I -->|是| J[显示结果]
    I -->|否| D
    J --> D
```

#oxdraw(mermaid-stm32)

==== FPGA数据接收流程

#let mermaid-fpga-rx = ```
graph LR
    A[FPGA复位] --> B[IDLE状态]
    B --> C{CLK上升沿?}
    C -->|是| D[采样数据写RAM]
    D --> E{接收784位?}
    E -->|否| C
    E -->|是| F[开始计算]
```

#oxdraw(mermaid-fpga-rx)

==== FPGA推理计算流程

#let mermaid-fpga-compute = ```
graph LR
    A[开始计算] --> B[Layer1: 3个神经元]
    B --> C[784次MAC运算]
    C --> D[ReLU激活]
    D --> E{所有神经元?}
    E -->|否| C
    E -->|是| F[Layer2: 10个输出]
    F --> G[Argmax]
    G --> H[输出结果]
```

#oxdraw(mermaid-fpga-compute)

==== 定时器中断流程（500Hz）

#let mermaid-timer = ```
graph LR
    A[TIM4中断500Hz] --> B{时钟使能?}
    B -->|否| C[返回]
    B -->|是| D{状态?}
    D -->|IDLE| E[CLK翻转]
    D -->|SENDING| F[发送数据位]
    F --> G{完成784位?}
    G -->|是| H[切换COMPUTING]
    G -->|否| E
    D -->|COMPUTING| I{FPGA完成?}
    I -->|是| J[读结果停时钟]
    I -->|否| E
    E --> C
    H --> C
    J --> C
```

#oxdraw(mermaid-timer)

=== 程序清单

==== FPGA核心模块

===== handwriting.v（顶层模块）

```verilog
// 手写数字识别顶层模块
module handwriting(
    input wire clk,
    input wire rst,
    input wire data_in,
    output wire busy,
    output wire [3:0] digit_out,
    output wire result_valid
);

    // 状态机定义
    localparam IDLE = 3'd0;
    localparam RECEIVING = 3'd1;
    localparam COMPUTING = 3'd2;
    localparam DONE = 3'd3;

    reg [2:0] state;

    // RAM模块信号
    reg ram_write_enable;
    wire [783:0] image_data;
    wire ram_data_ready;

    // MNIST模型信号
    reg mnist_start;
    wire mnist_valid;
    wire [3:0] mnist_digit_out;

    // 输出寄存器
    reg busy_reg;
    reg [3:0] digit_out_reg;
    reg result_valid_reg;

    assign busy = busy_reg;
    assign digit_out = digit_out_reg;
    assign result_valid = result_valid_reg;

    // 实例化RAM模块
    ram ram_inst (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .write_enable(ram_write_enable),
        .image_out(image_data),
        .data_ready(ram_data_ready)
    );

    // 实例化MNIST模型
    mnist_model mnist_inst (
        .clk(clk),
        .rst(rst),
        .image_in(image_data),
        .start(mnist_start),
        .digit_out(mnist_digit_out),
        .valid(mnist_valid)
    );

    // 主状态机
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            ram_write_enable <= 1'b1;
            mnist_start <= 1'b0;
            busy_reg <= 1'b0;
            digit_out_reg <= 4'd0;
            result_valid_reg <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    busy_reg <= 1'b0;
                    result_valid_reg <= 1'b0;
                    mnist_start <= 1'b0;
                    ram_write_enable <= 1'b1;
                    state <= RECEIVING;
                end

                RECEIVING: begin
                    busy_reg <= 1'b1;
                    ram_write_enable <= 1'b1;

                    if (ram_data_ready) begin
                        ram_write_enable <= 1'b0;
                        state <= COMPUTING;
                        mnist_start <= 1'b1;
                    end
                end

                COMPUTING: begin
                    mnist_start <= 1'b0;
                    busy_reg <= 1'b1;

                    if (mnist_valid) begin
                        digit_out_reg <= mnist_digit_out;
                        result_valid_reg <= 1'b1;
                        busy_reg <= 1'b0;
                        state <= DONE;
                    end
                end

                DONE: begin
                    result_valid_reg <= 1'b1;
                    busy_reg <= 1'b0;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
```

===== ram.v（数据缓存模块）

```verilog
// RAM模块 - 用于缓存从ARM传入的784位图像数据
module ram(
    input wire clk,
    input wire rst,
    input wire data_in,
    input wire write_enable,
    output reg [783:0] image_out,
    output reg data_ready
);

    reg [9:0] write_counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            image_out <= 784'b0;
            write_counter <= 10'd0;
            data_ready <= 1'b0;
        end else begin
            if (write_enable) begin
                image_out[write_counter] <= data_in;

                if (write_counter == 10'd783) begin
                    write_counter <= 10'd0;
                    data_ready <= 1'b1;
                end else begin
                    write_counter <= write_counter + 1'b1;
                    data_ready <= 1'b0;
                end
            end else begin
                if (write_counter == 10'd0) begin
                    data_ready <= 1'b0;
                end
            end
        end
    end

endmodule
```

==== STM32核心代码

===== fpga_comm.c（部分关键函数）

```c
void FPGA_Reset(void)
{
    extern void UART_Printf(const char *format, ...);
    volatile uint32_t delay;

    UART_Printf("[FPGA] Resetting FPGA...\r\n");

    // Reset sequence
    FPGA_RST_HIGH;
    for(delay = 0; delay < 168000; delay++);  // ~10ms
    FPGA_RST_LOW;
    for(delay = 0; delay < 16800; delay++);   // ~1ms

    fpga_state = FPGA_STATE_IDLE;
    fpga_data_index = 0;

    UART_Printf("[FPGA] Reset complete.\r\n");
}

void FPGA_StartSend(const uint8_t *data, uint16_t len)
{
    extern void UART_Printf(const char *format, ...);

    if(data == NULL || len > FPGA_DATA_SIZE) return;

    memcpy(fpga_data_buffer, data, len);
    FPGA_Reset();

    fpga_state = FPGA_STATE_IDLE;
    fpga_data_index = 0;
    clock_running = true;
    clock_tick_counter = 0;

    UART_Printf("[FPGA] Clock started...\r\n");
}
```

===== main.c（主程序框架）

```c
void UART_Printf(const char *format, ...)
{
    char buffer[256];
    va_list args;
    va_start(args, format);
    vsnprintf(buffer, sizeof(buffer), format, args);
    va_end(args);
    HAL_UART_Transmit(&huart1, (uint8_t *)buffer, strlen(buffer), 1000);
}

void UnpackDigitData(const uint8_t *packed_data, uint8_t *digit_data)
{
    for(uint16_t i = 0; i < PACKED_SIZE; i++)
    {
        uint8_t byte_val = packed_data[i];

        // 高半字节
        uint8_t high_nibble = (byte_val >> 4) & 0x0F;
        for(uint8_t j = 0; j < 4; j++)
        {
            uint16_t pixel_idx = i * 8 + j;
            if(pixel_idx < DIGIT_SIZE)
            {
                digit_data[pixel_idx] = (high_nibble >> (3 - j)) & 0x01;
            }
        }

        // 低半字节
        uint8_t low_nibble = byte_val & 0x0F;
        for(uint8_t j = 0; j < 4; j++)
        {
            uint16_t pixel_idx = i * 8 + 4 + j;
            if(pixel_idx < DIGIT_SIZE)
            {
                digit_data[pixel_idx] = (low_nibble >> (3 - j)) & 0x01;
            }
        }
    }
}
```
=== 实验现象
#link("https://www.bilibili.com/video/BV1NLqoBFE8U/")[
  #highlight[点击前往BiliBili观看实验视频]@bilibili
]

== 实验总结

=== 主要成果

在本次实验中，我成功实现了一个完整的手写数字识别系统，涵盖了从神经网络训练到硬件部署的全流程。系统采用STM32与FPGA协同工作的架构，实现了数据采集、LCD显示、神经网络推理和结果输出的完整闭环。在实现过程中，使用了清晰的状态机设计使系统易于调试和扩展。

=== 经验与收获

通过本次实验，我实现了多个学科知识的深度整合，将机器学习中的神经网络训练与量化技术、数字电路中的Verilog编程与状态机设计、嵌入式系统中的STM32外设控制与实时系统管理，以及UART和并行IO接口等通信协议有机结合起来。实验过程培养了我的工程优化思维，让我学会了在性能、资源和成本之间进行权衡取舍，通过量化分析指导设计决策，采用模块化设计便于系统的调试和维护。同时，我的实践能力得到了显著提升，不仅掌握了完整的嵌入式AI系统开发流程，还学会了使用ModelSim等仿真工具验证设计的正确性，并在硬件调试过程中积累了宝贵的经验，尤其是在时序同步、信号完整性分析等方面有了更深刻的理解。

#bibliography("refs.bib",style:"gb-7714-2005-numeric")

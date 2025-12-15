#import "@preview/basic-report:0.3.1": *
#import "@preview/oxdraw:0.1.0": *

#show: it => basic-report(
  doc-category: "计算机原理",
  doc-title: "存储器实验报告",
  author: "XXX 2023210XXX",
  affiliation: "20232111XX, 信息与通信工程学院, 北京邮电大学",
  logo: image("assets/bupt-logo.jpg", width: 3cm),
  language: "zh",
  heading-font: "Maple Mono NF",
  compact-mode: false,
  // show-outline: false,
  it,
)

= 实验二 存储器实验
== 实验目的
1. 熟练掌握GPIO输入输出操作。
2. 掌握存储器原理及应用。
3. 学会根据时序图编写程序。
== 实验要求
设计双端口存储器并使用ARM验证存储器功能，具体要求如下：
- 使用FPGA设计双端口存储器（要求时钟1位、写使能1位、其他自拟）。
- 使用STM32微控制器根据双端口存储器的读写时序和对应端口功能编写程序，通过对FPGA设计的双端口存储器进行读写测试，验证双端口存储器的功能。
== 实验任务
1. 基础部分
  - 基于FPGA设计存储器；
  - C编语言编程实现ARM对FPGA设计的存储器进行读写测试，并送指示灯显示数据；
2. 提高部分
  - 基于FPGA设计双存储器M1、M2；
  - C编语言编程实现ARM对M1、M2存储器读写操作，并从M1、M2某个地址单元中读取数据，将读取的数据进行运算，并将运算结果送到M1某个地址单元保存，再将结果读出送指示灯显示；

== 实验原理
双端口存储器简介

双端口存储器是指同一个存储器具有两组相互独立的读写控制线路,进行并行的独立操作，是一种高速工作的存储器。 
#figure(
  image("assets/image.png",width:90%),
  caption: [双端口存储器结构图]
)
- clock:系统时钟50Mhz，用于提供RAM读写数据；
- wraddress:写数据地址，将数据写入该地址的RAM存储区内；
- data:写入的数据0~7； 
- wren:写使能高电平有效；
- rdadress:读数据地址，将内存中的数据从RAM存储区读出； 
#figure(
  image("assets/image-1.png"),
  caption: [双端口存储器时序图-1]
)
#figure(
  image("assets/image-2.png"),
  caption: [双端口存储器时序图-2]
)
#pagebreak()
== 实验步骤
=== 程序流程图
系统启动后首先进行一系列初始化工作，包括HAL库初始化、系统时钟配置到82MHz工作频率、GPIO端口的配置以及定时器TIM4的初始化。定时器被设置为1ms的中断周期，用于实现数码管的动态扫描显示。随后对双RAM模块进行初始化，将所有控制信号设置为初始状态，并启动定时器中断。在进入主循环之前，系统会预先从两个RAM中读取一次数据，确保显示内容的正确性。

进入主循环后，系统持续执行一个固定的任务序列。首先读取8位拨码开关的状态，从中解析出各种控制参数：SW0控制读写模式、SW1选择操作的RAM、SW2和SW3组成2位待写入数据、SW4和SW5组成2位地址信息。然后根据这些状态更新8个LED指示灯的显示，让用户直观了解当前系统配置。接着从两个RAM中分别读取当前地址的数据，更新数码管显示缓冲区的内容。每次循环结束后延时50ms，既保证了系统响应的及时性，又避免了过度占用CPU资源。

与主循环并行工作的是两个中断服务程序。定时器中断每1ms触发一次，负责数码管的动态扫描显示，通过74HC595移位寄存器发送段选数据，通过74HC138译码器选择当前点亮的数码管位，实现8位数码管的流畅显示。按钮中断响应用户的操作请求，按钮0在写入模式下将拨码开关设定的数据写入选定的RAM，按钮1则执行更复杂的异或运算，它会读取两个RAM相同地址的数据，进行按位异或后将结果写回到用户选定的RAM中。所有中断处理完成后都会添加20ms的消抖延时，确保操作的可靠性。

具体流程图如 @figure-3-4 所示。
#figure(
  oxdraw("
graph TD
    A[系统启动] --> B[初始化外设]
    B --> C[HAL库初始化]
    C --> D[系统时钟配置82MHz]
    D --> E[GPIO端口初始化]
    E --> F[定时器TIM4初始化1ms]
    F --> G[双RAM初始化]
    G --> H[启动定时器中断]
    H --> I[初始读取RAM数据]

    I --> J{主循环开始}

    J --> K[读取拨码开关状态]
    K --> L[解析SW0-SW5配置]
    L --> M[更新LED指示灯]
    M --> N[从RAM0读取数据]
    N --> O[从RAM1读取数据]
    O --> P[更新数码管显示缓冲]
    P --> Q[延时50ms]
    Q --> J

    J -.按钮中断.-> R{检测按钮}
    R -->|按钮0 PC9| S{是否写入模式?}
    S -->|是| T[写数据到选定RAM]
    S -->|否| U[忽略操作]
    T --> V[消抖延时20ms]
    U --> J
    V --> J

    R -->|按钮1 PC12| W[读取两个RAM数据]
    W --> X[执行异或运算]
    X --> Y[结果写回选定RAM]
    Y --> Z[消抖延时20ms]
    Z --> J

    J -.定时器中断1ms.-> AA[TIM4中断触发]
    AA --> AB[更新数码管扫描]
    AB --> AC[切换到下一位]
    AC --> AD[通过74HC595发送段码]
    AD --> AE[通过74HC138选择位]
    AE --> J
  "),
)<figure-3-4>

=== 程序清单
+ 主程序文件
  + 全局变量定义
    ```c
    /* 定时器句柄，用于数码管扫描 */
    TIM_HandleTypeDef htim4;

    /* 系统状态结构体，存储当前配置和RAM数据 */
    SystemState_t sys_state = {0};

    /* 数码管显示缓冲区，8位数码管对应8个字节 */
    volatile uint8_t display_buffer[8] = {0};

    /* 当前扫描的数码管位号(0-7) */
    volatile uint8_t current_digit = 0;

    /* 共阴数码管段码表，0-9和A-F的显示编码 */
    const uint8_t DigitCode[16] = {
        0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07,
        0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71
    };
    ```

  + 74HC595移位寄存器驱动函数

    ```c
    /* 通过SPI方式向74HC595发送一个字节数据，控制数码管段选 */
    void HC595_SendByte(uint8_t data) {
        /* 锁存信号拉低，准备接收数据 */
        HAL_GPIO_WritePin(HC595_RCK_PORT, HC595_RCK_PIN, GPIO_PIN_RESET);
        
        /* 从高位到低位依次发送8位数据 */
        for (int i = 7; i >= 0; i--) {
            /* 时钟信号拉低 */
            HAL_GPIO_WritePin(HC595_SCK_PORT, HC595_SCK_PIN, GPIO_PIN_RESET);
            
            /* 设置数据线电平 */
            if (data & (1 << i)) {
                HAL_GPIO_WritePin(HC595_SI_PORT, HC595_SI_PIN, GPIO_PIN_SET);
            } else {
                HAL_GPIO_WritePin(HC595_SI_PORT, HC595_SI_PIN, GPIO_PIN_RESET);
            }
            
            /* 时钟上升沿，数据被移入寄存器 */
            HAL_GPIO_WritePin(HC595_SCK_PORT, HC595_SCK_PIN, GPIO_PIN_SET);
        }
        
        /* 锁存信号拉高，数据输出到Q0-Q7引脚 */
        HAL_GPIO_WritePin(HC595_RCK_PORT, HC595_RCK_PIN, GPIO_PIN_SET);
    }
    ```

  + 74HC138译码器选择函数

    ```c
    /* 通过3-8译码器选择要点亮的数码管位(0-7) */
    void HC138_Select(uint8_t digit) {
        /* A、B、C三个输入引脚组成3位二进制地址 */
        HAL_GPIO_WritePin(HC138_A_PORT, HC138_A_PIN, (digit & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
        HAL_GPIO_WritePin(HC138_B_PORT, HC138_B_PIN, (digit & 0x02) ? GPIO_PIN_SET : GPIO_PIN_RESET);
        HAL_GPIO_WritePin(HC138_C_PORT, HC138_C_PIN, (digit & 0x04) ? GPIO_PIN_SET : GPIO_PIN_RESET);
    }
    ```

  + 数码管扫描更新函数

    ```c
    /* 在定时器中断中调用，实现动态扫描显示 */
    void Update_Display(void) {
        /* 先关闭当前显示，避免重影 */
        HC595_SendByte(0x00);
        
        /* 切换到下一位数码管(循环0-7) */
        current_digit = (current_digit + 1) % 8;
        
        /* 选择对应的位并发送段码数据 */
        HC138_Select(current_digit);
        HC595_SendByte(display_buffer[current_digit]);
    }
    ```

  + 拨码开关读取函数

    ```c
    /* 读取PC0-PC7的拨码开关状态并解析配置 */
    void Read_Switches(void) {
        /* 直接读取GPIOC的输入数据寄存器低8位 */
        uint8_t sw_value = (GPIOC->IDR & 0xFF);
        
        /* 解析各个控制位 */
        sys_state.write_mode = (sw_value & 0x01) ? 1 : 0;        // SW0: 读写模式
        sys_state.ram_select = (sw_value & 0x02) ? 1 : 0;        // SW1: RAM选择
        sys_state.data_to_write = (sw_value >> 2) & 0x03;        // SW2-3: 待写数据
        sys_state.addr = (sw_value >> 4) & 0x03;                 // SW4-5: 地址
    }
    ```

  + LED状态指示函数

    ```c
    /* 根据系统状态更新LED显示 */
    void Update_LEDs(void) {
        uint8_t led_state = 0;
        
        led_state |= 0x01;                          // LED0: 系统运行指示
        if (sys_state.write_mode) led_state |= 0x02;    // LED1: 写入模式
        if (!sys_state.ram_select) led_state |= 0x04;   // LED2: RAM0选中
        if (sys_state.ram_select) led_state |= 0x08;    // LED3: RAM1选中
        if (sys_state.addr & 0x01) led_state |= 0x10;   // LED4: 地址位0
        if (sys_state.addr & 0x02) led_state |= 0x20;   // LED5: 地址位1
        
        /* 更新GPIOB的低8位输出 */
        GPIOB->ODR = (GPIOB->ODR & 0xFF00) | led_state;
    }
    ```

  + RAM初始化函数

    ```c
    /* 初始化双RAM模块的控制信号 */
    void RAM_Init(void) {
        /* 将所有控制信号设置为低电平初始状态 */
        HAL_GPIO_WritePin(RAM_CLKA_PORT, RAM_CLKA_PIN, GPIO_PIN_RESET);
        HAL_GPIO_WritePin(RAM_CLKB_PORT, RAM_CLKB_PIN, GPIO_PIN_RESET);
        HAL_GPIO_WritePin(RAM_ENA_PORT, RAM_ENA_PIN, GPIO_PIN_RESET);
        HAL_GPIO_WritePin(RAM_ENB_PORT, RAM_ENB_PIN, GPIO_PIN_RESET);
        HAL_GPIO_WritePin(RAM_WEA_PORT, RAM_WEA_PIN, GPIO_PIN_RESET);
        HAL_GPIO_WritePin(RAM_WEB_PORT, RAM_WEB_PIN, GPIO_PIN_RESET);
    }
    ```

  + RAM写入函数

    ```c
    /* 向指定RAM的指定地址写入2位数据 */
    void RAM_Write(uint8_t ram_sel, uint8_t addr, uint8_t data) {
        if (ram_sel == 0) {
            /* 操作RAM0，使用端口A */
            HAL_GPIO_WritePin(RAM_ADDRA_PORT, RAM_ADDRA_PIN, (addr & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
            HAL_GPIO_WritePin(RAM_DIA0_PORT, RAM_DIA0_PIN, (data & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
            HAL_GPIO_WritePin(RAM_DIA1_PORT, RAM_DIA1_PIN, (data & 0x02) ? GPIO_PIN_SET : GPIO_PIN_RESET);
            
            /* 使能写入模式 */
            HAL_GPIO_WritePin(RAM_WEA_PORT, RAM_WEA_PIN, GPIO_PIN_SET);
            HAL_GPIO_WritePin(RAM_ENA_PORT, RAM_ENA_PIN, GPIO_PIN_SET);
            
            /* 产生时钟上升沿，数据被写入 */
            HAL_GPIO_WritePin(RAM_CLKA_PORT, RAM_CLKA_PIN, GPIO_PIN_RESET);
            HAL_Delay(1);
            HAL_GPIO_WritePin(RAM_CLKA_PORT, RAM_CLKA_PIN, GPIO_PIN_SET);
            HAL_Delay(1);
            HAL_GPIO_WritePin(RAM_CLKA_PORT, RAM_CLKA_PIN, GPIO_PIN_RESET);
            
            /* 关闭使能信号 */
            HAL_GPIO_WritePin(RAM_ENA_PORT, RAM_ENA_PIN, GPIO_PIN_RESET);
            HAL_GPIO_WritePin(RAM_WEA_PORT, RAM_WEA_PIN, GPIO_PIN_RESET);
        } else {
            /* 操作RAM1，使用端口B，流程相同 */
            HAL_GPIO_WritePin(RAM_ADDRB_PORT, RAM_ADDRB_PIN, (addr & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
            HAL_GPIO_WritePin(RAM_DIB0_PORT, RAM_DIB0_PIN, (data & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
            HAL_GPIO_WritePin(RAM_DIB1_PORT, RAM_DIB1_PIN, (data & 0x02) ? GPIO_PIN_SET : GPIO_PIN_RESET);
            
            HAL_GPIO_WritePin(RAM_WEB_PORT, RAM_WEB_PIN, GPIO_PIN_SET);
            HAL_GPIO_WritePin(RAM_ENB_PORT, RAM_ENB_PIN, GPIO_PIN_SET);
            
            HAL_GPIO_WritePin(RAM_CLKB_PORT, RAM_CLKB_PIN, GPIO_PIN_RESET);
            HAL_Delay(1);
            HAL_GPIO_WritePin(RAM_CLKB_PORT, RAM_CLKB_PIN, GPIO_PIN_SET);
            HAL_Delay(1);
            HAL_GPIO_WritePin(RAM_CLKB_PORT, RAM_CLKB_PIN, GPIO_PIN_RESET);
            
            HAL_GPIO_WritePin(RAM_ENB_PORT, RAM_ENB_PIN, GPIO_PIN_RESET);
            HAL_GPIO_WritePin(RAM_WEB_PORT, RAM_WEB_PIN, GPIO_PIN_RESET);
        }
    }
    ```

  + RAM读取函数

    ```c
    /* 从指定RAM的指定地址读取2位数据 */
    void RAM_Read(uint8_t ram_sel, uint8_t addr) {
        if (ram_sel == 0) {
            /* 读取RAM0 */
            HAL_GPIO_WritePin(RAM_ADDRA_PORT, RAM_ADDRA_PIN, (addr & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
            
            /* 关闭写使能，开启读模式 */
            HAL_GPIO_WritePin(RAM_WEA_PORT, RAM_WEA_PIN, GPIO_PIN_RESET);
            HAL_GPIO_WritePin(RAM_ENA_PORT, RAM_ENA_PIN, GPIO_PIN_SET);
            
            /* 产生时钟上升沿 */
            HAL_GPIO_WritePin(RAM_CLKA_PORT, RAM_CLKA_PIN, GPIO_PIN_RESET);
            HAL_Delay(1);
            HAL_GPIO_WritePin(RAM_CLKA_PORT, RAM_CLKA_PIN, GPIO_PIN_SET);
            HAL_Delay(1);
            
            /* 从输出端口读取数据 */
            uint8_t data = 0;
            if (HAL_GPIO_ReadPin(RAM_DOA0_PORT, RAM_DOA0_PIN)) data |= 0x01;
            if (HAL_GPIO_ReadPin(RAM_DOA1_PORT, RAM_DOA1_PIN)) data |= 0x02;
            sys_state.ram0_data = data;
            
            HAL_GPIO_WritePin(RAM_CLKA_PORT, RAM_CLKA_PIN, GPIO_PIN_RESET);
            HAL_GPIO_WritePin(RAM_ENA_PORT, RAM_ENA_PIN, GPIO_PIN_RESET);
        } else {
            /* 读取RAM1，流程相同 */
            HAL_GPIO_WritePin(RAM_ADDRB_PORT, RAM_ADDRB_PIN, (addr & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
            
            HAL_GPIO_WritePin(RAM_WEB_PORT, RAM_WEB_PIN, GPIO_PIN_RESET);
            HAL_GPIO_WritePin(RAM_ENB_PORT, RAM_ENB_PIN, GPIO_PIN_SET);
            
            HAL_GPIO_WritePin(RAM_CLKB_PORT, RAM_CLKB_PIN, GPIO_PIN_RESET);
            HAL_Delay(1);
            HAL_GPIO_WritePin(RAM_CLKB_PORT, RAM_CLKB_PIN, GPIO_PIN_SET);
            HAL_Delay(1);
            
            uint8_t data = 0;
            if (HAL_GPIO_ReadPin(RAM_DOB0_PORT, RAM_DOB0_PIN)) data |= 0x01;
            if (HAL_GPIO_ReadPin(RAM_DOB1_PORT, RAM_DOB1_PIN)) data |= 0x02;
            sys_state.ram1_data = data;
            
            HAL_GPIO_WritePin(RAM_CLKB_PORT, RAM_CLKB_PIN, GPIO_PIN_RESET);
            HAL_GPIO_WritePin(RAM_ENB_PORT, RAM_ENB_PIN, GPIO_PIN_RESET);
        }
    }
    ```

  + 数码管显示缓冲更新函数

    ```c
    /* 根据RAM数据更新数码管显示内容 */
    void Update_Display_Buffer(void) {
        /* 位1: RAM1数据的第0位 */
        display_buffer[0] = (sys_state.ram1_data & 0x01) ? DigitCode[1] : DigitCode[0];
        
        /* 位2: RAM1数据的第1位 */
        display_buffer[1] = (sys_state.ram1_data & 0x02) ? DigitCode[1] : DigitCode[0];
        
        /* 位3: RAM0数据的第0位，带小数点 */
        display_buffer[2] = ((sys_state.ram0_data & 0x01) ? DigitCode[1] : DigitCode[0]) | 0x80;
        
        /* 位4: RAM0数据的第1位 */
        display_buffer[3] = (sys_state.ram0_data & 0x02) ? DigitCode[1] : DigitCode[0];
        
        /* 位5-7: 保留不显示 */
        display_buffer[4] = 0x00;
        display_buffer[5] = 0x00;
        display_buffer[6] = 0x00;
        
        /* 位8: 显示待写入的数据值(0-3) */
        display_buffer[7] = DigitCode[sys_state.data_to_write];
    }
    ```

  + 主函数

    ```c
    int main(void) {
        /* HAL库初始化 */
        HAL_Init();
        
        /* 配置系统时钟到82MHz */
        SystemClock_Config();
        
        /* 初始化GPIO和定时器 */
        MX_GPIO_Init();
        MX_TIM4_Init();
        
        /* 初始化双RAM模块 */
        RAM_Init();
        
        /* 启动定时器中断，开始数码管扫描 */
        HAL_TIM_Base_Start_IT(&htim4);
        
        /* 预读取RAM数据 */
        RAM_Read(0, sys_state.addr);
        RAM_Read(1, sys_state.addr);
        
        /* 主循环 */
        while (1) {
            Read_Switches();          // 读取拨码开关
            Update_LEDs();            // 更新LED指示
            RAM_Read(0, sys_state.addr);  // 读RAM0
            RAM_Read(1, sys_state.addr);  // 读RAM1
            Update_Display_Buffer();   // 更新显示
            HAL_Delay(50);            // 延时50ms
        }
    }
    ```

  + 中断服务函数

    ```c
    /* GPIO外部中断回调函数，处理按钮事件 */
    void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin) {
        if (GPIO_Pin == GPIO_PIN_9) {
            /* 按钮0：写入数据 */
            if (sys_state.write_mode) {
                RAM_Write(sys_state.ram_select, sys_state.addr, sys_state.data_to_write);
            }
            HAL_Delay(20);  // 消抖
        } 
        else if (GPIO_Pin == GPIO_PIN_12) {
            /* 按钮1：异或操作 */
            RAM_Read(0, sys_state.addr);
            RAM_Read(1, sys_state.addr);
            uint8_t xor_result = sys_state.ram0_data ^ sys_state.ram1_data;
            RAM_Write(sys_state.ram_select, sys_state.addr, xor_result);
            HAL_Delay(20);  // 消抖
        }
    }

    /* 定时器中断回调函数，用于数码管扫描 */
    void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim) {
        if (htim->Instance == TIM4) {
            Update_Display();  // 每1ms更新一次数码管
        }
    }
    ```

+ 头文件

  + 系统状态结构体定义

    ```c
    /* 系统状态数据结构 */
    typedef struct {
        uint8_t write_mode;      // SW0: 0=读出模式, 1=写入模式
        uint8_t ram_select;      // SW1: 0=选择RAM0, 1=选择RAM1
        uint8_t data_to_write;   // SW2-3: 待写入数据(0-3)
        uint8_t addr;            // SW4-5: 地址选择(0-3)
        uint8_t ram0_data;       // 从RAM0读取的数据
        uint8_t ram1_data;       // 从RAM1读取的数据
    } SystemState_t;
    ```

  + 引脚宏定义

    ```c
    /* 74HC595控制引脚(数码管段选) */
    #define HC595_SI_PIN    GPIO_PIN_0    // 串行数据输入
    #define HC595_SI_PORT   GPIOA
    #define HC595_RCK_PIN   GPIO_PIN_1    // 锁存时钟
    #define HC595_RCK_PORT  GPIOA
    #define HC595_SCK_PIN   GPIO_PIN_2    // 移位时钟
    #define HC595_SCK_PORT  GPIOA

    /* 74HC138控制引脚(数码管位选) */
    #define HC138_A_PIN     GPIO_PIN_3
    #define HC138_A_PORT    GPIOA
    #define HC138_B_PIN     GPIO_PIN_4
    #define HC138_B_PORT    GPIOA
    #define HC138_C_PIN     GPIO_PIN_5
    #define HC138_C_PORT    GPIOA

    /* LED端口(PB0-PB7) */
    #define LED_PORT        GPIOB

    /* 拨码开关端口(PC0-PC7) */
    #define SW_PORT         GPIOC

    /* 双RAM接口引脚(PF端口) */
    #define RAM_CLKA_PIN    GPIO_PIN_6     // RAM端口A时钟
    #define RAM_CLKB_PIN    GPIO_PIN_14    // RAM端口B时钟
    #define RAM_ENA_PIN     GPIO_PIN_1     // RAM端口A使能
    #define RAM_ENB_PIN     GPIO_PIN_9     // RAM端口B使能
    #define RAM_WEA_PIN     GPIO_PIN_0     // RAM端口A写使能
    #define RAM_WEB_PIN     GPIO_PIN_8     // RAM端口B写使能
    #define RAM_ADDRA_PIN   GPIO_PIN_7     // RAM端口A地址
    #define RAM_ADDRB_PIN   GPIO_PIN_15    // RAM端口B地址
    #define RAM_DIA0_PIN    GPIO_PIN_4     // RAM端口A数据输入位0
    #define RAM_DIA1_PIN    GPIO_PIN_5     // RAM端口A数据输入位1
    #define RAM_DIB0_PIN    GPIO_PIN_12    // RAM端口B数据输入位0
    #define RAM_DIB1_PIN    GPIO_PIN_13    // RAM端口B数据输入位1
    #define RAM_DOA0_PIN    GPIO_PIN_2     // RAM端口A数据输出位0
    #define RAM_DOA1_PIN    GPIO_PIN_3     // RAM端口A数据输出位1
    #define RAM_DOB0_PIN    GPIO_PIN_10    // RAM端口B数据输出位0
    #define RAM_DOB1_PIN    GPIO_PIN_11    // RAM端口B数据输出位1
    ```

+ FPGA双端口RAM模块
  ```verilog
  module dual_ram(
      input clka,    // 端口A时钟信号 - PIN_54(PF6)
      input clkb,    // 端口B时钟信号 - PIN_53(PF14)

      input ena,     // 端口A使能信号 - PIN_69(PF1)
      input enb,     // 端口B使能信号 - PIN_68(PF9)

      input wea,     // 端口A写使能信号 - PIN_71(PF0)
      input web,     // 端口B写使能信号 - PIN_70(PF8)

      input  addra,   // 端口A地址(1位) - PIN_58(PF7)
      input  addrb,   // 端口B地址(1位) - PIN_55(PF15)

      input [1:0] data_i_a,      // 端口A数据输入(2位) - data_i_a[0]:PIN_60(PF4) data_i_a[1]:PIN_52(PF5)
      input [1:0] data_i_b,      // 端口B数据输入(2位) - data_i_b[0]:PIN_59(PF12) data_i_b[1]:PIN_51(PF13)

      output reg [1:0] data_o_a, // 端口A数据输出(2位) - data_o_a[0]:PIN_67(PF2) data_o_a[1]:PIN_65(PF3)
      output reg [1:0] data_o_b  // 端口B数据输出(2位) - data_o_b[0]:PIN_66(PF10) data_o_b[1]:PIN_64(PF11)
  );

  /* 定义两个独立的2位宽、深度为2的RAM存储阵列 */
  reg [1:0] RAMA [1:0];  // RAM A存储单元，支持通过端口A访问
  reg [1:0] RAMB [1:0];  // RAM B存储单元，支持通过端口B访问

  /* 端口A操作逻辑：在时钟上升沿触发 */
  always @(posedge clka) begin
      if(ena) begin              // 使能信号有效时
          if(wea) begin          // 写模式：将输入数据写入RAMA
              RAMA[addra] <= data_i_a;
          end
          data_o_a <= RAMA[addra];  // 读模式：输出RAMA数据(写后读)
      end
  end

  /* 端口B操作逻辑：在时钟上升沿触发 */
  always @(posedge clkb) begin
      if(enb) begin              // 使能信号有效时
          if(web) begin          // 写模式：将输入数据写入RAMB
              RAMB[addrb] <= data_i_b;
          end
          data_o_b <= RAMB[addrb];  // 读模式：输出RAMB数据(写后读)
      end
  end

  endmodule
  ```
=== 实现方式

本实验采用STM32微控制器与FPGA协同工作的方式实现双端口存储器系统。核心存储单元由FPGA实现，使用Verilog硬件描述语言编写了dual_ram模块，该模块在FPGA内部例化了两个独立的RAM存储阵列RAMA和RAMB，每个RAM具有2位数据宽度和2个存储单元深度。FPGA提供了两个完全独立的访问端口A和B，每个端口都有自己的时钟、使能、写使能、地址和数据总线，实现了真正的双端口并行访问能力。

STM32作为主控制器，通过PF端口的16个GPIO引脚与FPGA建立通信接口。这些引脚分别连接到FPGA的时钟、使能、写使能、地址和双向数据线。STM32通过软件模拟同步时序协议来控制RAM的读写操作。写入操作时，STM32先设置地址和数据线电平，然后拉高写使能和端口使能信号，最后产生一个完整的时钟脉冲，在上升沿将数据锁存到FPGA的RAM中。读取操作时，STM32设置地址后关闭写使能，产生时钟脉冲，然后从数据输出引脚读取FPGA返回的数据。

人机交互方面，系统使用8位拨码开关作为输入设备，通过不同的开关组合来配置读写模式、RAM选择、数据值和地址值。8个LED灯实时反映系统当前状态，让用户可以直观地看到模式、选择和地址信息。显示输出采用8位共阴数码管动态扫描方式，通过74HC595移位寄存器驱动段选，74HC138译码器驱动位选，在1ms定时器中断中循环扫描各位，以125Hz的刷新率实现稳定的显示效果。两个按钮通过GPIO外部中断实现即时响应，按钮0执行数据写入功能，按钮1执行更复杂的异或运算功能，所有按钮操作都经过软件消抖处理。

整个系统的工作流程是：主循环以50ms为周期持续监测拨码开关状态并读取RAM数据，定时器中断以1ms为周期刷新数码管显示，按钮中断异步响应用户的操作请求。这种多任务协作的架构保证了系统的实时性和流畅性，实现了一个功能完整、交互友好的双端口存储器实验平台。通过这种STM32+FPGA的混合架构，既利用了FPGA在并行逻辑处理和真正双端口实现上的优势，又发挥了STM32在控制逻辑、外设驱动和人机交互方面的灵活性。

== 实验总结
通过本次双端口存储器实验，我深刻体会到了嵌入式系统开发中硬件与软件协同设计的重要性。在实验过程中，我不仅学会了使用Verilog在FPGA中实现真正的双端口RAM结构，还掌握了STM32与FPGA之间的接口时序设计和通信协议。特别是在调试过程中遇到的时序不匹配问题，让我认识到在跨芯片通信中必须严格遵守建立时间和保持时间的要求，这需要对硬件时序有深入的理解。数码管动态扫描的实现也让我理解了分时复用技术的精髓，通过定时器中断实现高频刷新，既节省了IO资源又获得了良好的显示效果。

整个实验最大的收获是培养了系统化思维能力。从顶层架构设计、模块功能划分、接口协议定义到最终的调试验证，每个环节都需要全面考虑。异或运算功能的实现让我体会到双端口RAM在数据处理中的优势，两个端口可以同时访问不同的存储单元，大大提高了数据吞吐效率。同时，通过LED指示、数码管显示和拨码开关输入的综合运用，我学会了如何设计直观友好的人机交互界面。这次实验不仅巩固了数字电路和嵌入式编程的理论知识，更重要的是锻炼了分析问题、解决问题的实践能力，为今后从事更复杂的嵌入式系统开发打下了坚实的基础。

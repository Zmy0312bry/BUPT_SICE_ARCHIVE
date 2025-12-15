#import "@preview/basic-report:0.3.1": *
#import "@preview/oxdraw:0.1.0": *

#show: it => basic-report(
  doc-category: "计算机原理",
  doc-title: "外部中断实验报告",
  author: "XXX 2023210XXX",
  affiliation: "20232111XX, 信息与通信工程学院, 北京邮电大学",
  logo: image("assets/bupt-logo.jpg", width: 3cm),
  language: "zh",
  heading-font: "Maple Mono NF",
  compact-mode: false,
  // show-outline: false,
  it,
)

= 实验三 外部中断实验报告
== 实验目的
1. 掌握NVIC中断优先级配置。
2. 学会外部中断配置。
== 实验要求
学习和掌握中断的概念，设计并实现外部中断功能。
== 实验任务
1. 基础部分

  用C语言编程实现以下功能，系统上电时执行主程序，程序可采用第一次实验的LED流水灯程序；使用按键做外部中断源输入，当按键有按下时触发中断，中断程序可以控制交通灯的亮灭，亮灭方式自定；

2. 提高部分

  用C语言编程实现系统上电时执行主程序，程序实现用1位数码管显示0-9数字；使用2个按键做外部中断源输入，当按键有按下时触发中断，考虑中断的优先级问题，自拟中断服务程序，实现并演示；
== 实验原理
电路结构如 @figure-3-1 所示
#figure(
  image("assets/image.png"),
  caption: [电路结构图],
)<figure-3-1>
=== NVIC中断优先级
NVIC是嵌套向量中断控制器，控制着整个芯片中断相关的功能，它跟内核紧密耦合，是内核里面的一个外设。但是各个芯片厂商在设计芯片的时候会对Cortex-M4内核里面的NVIC进行裁剪，把不需要的部分去掉，所以说STM32的NVIC是Cortex-M4的NVIC的一个子集。

CM4内核可以支持256个中断，包括16个内核中断和240个外部中断，256级的可编程中断设置。对于STM32F4没有用到CM4内核的所有东西，只是用到了一部分，对于STM32F40和41系列共有92个中断，其中有10个内核中断和82个可屏蔽中断，常用的为82个可屏蔽中断。

ISER[8]—中断使能寄存器组，用来使能中断，每一位控制一个中断，由于上面已经说明了控制82个可屏蔽的中断，因此利用ISER[0\~2]这三个32位寄存器就够了。一下的几个寄存器同理。

- ICER[8]—中断除能寄存器组，用来消除中断。
- ISPR[8]—中断挂起控制寄存器组，用来挂起中断。
- ICPR[8]—中断解挂控制寄存器组，用来解除挂起。
- IABR[8]—中断激活标志寄存器组，对应位如果为1则表示中断正在被执行。
- IP[240]—中断优先级控制寄存器组，它是用来设置中断优先级的。
我们只用到了IP[0]\~IP[81]，每个寄存器只用到了高4位，这4位又用来设置抢占优先级和响应优先级（有关抢占优先级和响应优先级后面会介绍到），而对于抢占优先级和响应优先级各占多少位则由AIRCR寄存器控制，相关设置如 @table-3-1 所示。

#figure(
  table(
    columns: 4,
    align: center,
    [组], [AIRCR\[10:8\]], [bit\[7:4\]分配情况], [分配结果],
    [0], [111], [0:4], [0位抢占优先级,4位响应优先级],
    [1], [110], [1:3], [1位抢占优先级,3位响应优先级],
    [2], [101], [2:2], [2位抢占优先级,2位响应优先级],
    [3], [100], [3:1], [3位抢占优先级,1位响应优先级],
    [4], [011], [4:0], [4位抢占优先级,0位响应优先级],
  ),
  caption: [AIRCR寄存器优先级分配],
)<table-3-1>

关于抢占优先级和响应优先级的理解，可以将它们简单的理解为两个级别，抢占优先级的级别要比响应优先级的级别高，简单的理解为一个为长辈的一个为晚辈的，晚辈要让着长辈，因此抢占优先级的中断可以打断响应优先级的中断，而同级别的中断就得有个先来后到的了，先来的先执行。抢占优先级与相应优先级示例，如 @table-3-2 所示。
#figure(
  table(
    columns: 4,
    align: center,
    [中断向量], [抢占优先级], [响应优先级], [说明],
    [A], [0], [1], table.cell(rowspan: 2)[抢占优先级相同,响应优先级数值小的优先级高],
    [B], [0], [2],
    [A], [1], [2], table.cell(rowspan: 2)[响应优先级相同,抢占优先级数值小的优先级高],
    [B], [0], [2],
    [A], [1], [0], table.cell(rowspan: 2)[抢占优先级比响应优先级高],
    [B], [0], [2],
    [A], [1], [1], table.cell(rowspan: 2)[抢占优先级和响应优先级均相同,则中断向量编号小的先执行],
    [B], [1], [1],
  ),
  caption: [抢占优先级与响应优先级示例],
)<table-3-2>
=== 外部中断
外部中断/事件控制器(EXTI)管理了控制器的23个中断/事件线。每个中断/事件线都对应有一个边沿检测器，可以实现输入信号的上升沿检测和下降沿的检测。EXTI可以实现对每个中断/事件线进行单独配置，可以单独配置为中断或者事件，以及触发事件的属性。
EXTI功能框图如 @figure-3-2 所示。
#figure(
  image("assets/image-1.png"),
  caption: [EXTI功能框图],
)<figure-3-2>
在 @figure-3-2 中在信号线上打一个斜杠并标注“23”字样表示在控制器内部类似的信号线路有23个，这与EXTI总共有23个中断/事件线是吻合的。

EXTI可分为两大部分功能，一个是产生中断，另一个是产生事件。@figure-3-2 中线路①②③④⑤指示的电路流程是一个产生中断的线路，最终信号流入到NVIC控制器内。

编号1是输入线，EXTI控制器有23个中断/事件输入线，这些输入线可以通过寄存器设置为任意一个GPIO，也可以是一些外设的事件，输入线一般是存在电平变化的信号。

编号2是一个边沿检测电路，它会根据上升沿触发选择寄存器(EXTI_RTSR)和下降沿触发选择寄存器(EXTI_FTSR)对应位的设置来控制信号触发。边沿检测电路以输入线作为信号输入端，如果检测到有边沿跳变就输出有效信号1给编号3电路，否则输出无效信号0。而EXTI_RTSR和EXTI_FTSR两个寄存器可以控制器需要检测哪些类型的电平跳变过程，可以是只有上升沿触发、只有下降沿触发或者上升沿和下降沿都触发。

编号3电路实际就是一个或门电路，它一个输入来自编号2电路，另外一输入来自软件中断事件寄存器(EXTI_SWIER)。EXTI_SWIER允许我们通过程序控制就可以启动中断/事件线，这在某些地方非常有用。

编号4电路是一个与门电路，它一个输入编号3电路，另外一个输入来自中断屏蔽寄存器(EXTI_IMR)。与门电路要求输入都为1才输出1，导致的结果如果EXTI_IMR设置为0时，那不管编号3电路的输出信号是1还是0，最终编号4电路输出的信号都为0；如果EXTI_IMR设置为1时，最终编号4电路输出的信号才由编号3电路的输出信号决定，这样我们可以简单的控制EXTI_IMR来实现是否产生中断的目的。编号4电路输出的信号会被保存到挂起寄存器(EXTI_PR)内，如果确定编号4电路输出为1就会把EXTI_PR对应位置1。

编号5是将EXTI_PR寄存器内容输出到NVIC内，从而实现系统中断事件控制。它是一个产生事件的线路，最终输出一个脉冲信号。

编号6电路是一个与门，它一个输入编号3电路，另外一个输入来自事件屏蔽寄存器(EXTI_EMR)。如果EXTI_EMR设置为0时，那不管编号3电路的输出信号是1还是0，最终编号6电路输出的信号都为0；如果EXTI_EMR设置为1时，最终编号6电路输出的信号才由编号3电路的输出信号决定，这样我们可以简单的控制、EXTI_EMR来实现是否产生事件的目的。

编号7是一个脉冲发生器电路，当它的输入端，即编号6电路的输出端，是一个有效信号1时就会产生一个脉冲；如果输入端是无效信号就不会输出脉冲。

编号8是一个脉冲信号，就是产生事件的线路最终的产物，这个脉冲信号可以给其他外设电路使用，比如定时器TIM、模拟数字转换器ADC等等。

产生中断线路目的是把输入信号输入到NVIC，进一步会运行中断服务函数，实现功能，这样是软件级的。而产生事件线路目的就是传输一个脉冲信号给其他外设使用，并且是电路级别的信号传输，属于硬件级的。

EXTI有23个中断/事件线，每个GPIO都可以被设置为外部中断的中断输入口，这点也是STM32F4的强大之处。STM32F407的中断控制器支持23个外部中断/事件请求。每个中断设有状态位，每个中断/事件都有独立的触发和屏蔽设置。STM32F407的23个外部中断为：
- EXTI线0\~15：对应外部IO口的输入中断。
- EXTI线16：连接到PVD输出。
- EXTI线17：连接到RTC闹钟事件。
- EXTI线18：连接到USB OTG FS唤醒事件。
- EXTI线19：连接到以太网唤醒事件。
- EXTI线20：连接到USB OTG HS(在FS中配置)唤醒事件。
- EXTI线21：连接到RTC入侵和时间戳事件。
- EXTI线22：连接到RTC唤醒事件。
STM32F4供IO口使用的中断线只有16个，但是STM32F4的IO口却远远不止16个，那么STM32F4是怎么把16个中断线和IO口一一对应起来的呢？于是STM32就这样设计，GPIO的管脚GPIOx.0\~GPIOx.15(x=A,B,C,D,E，F,G,H,I)分别对应中断线0\~15。这样每个中断线对应了最多9个IO口，以线0为例：它对应了GPIOA.0、GPIOB.0、GPIOC.0、GPIOD.0、GPIOE.0、GPIOF.0、GPIOG.0、GPIOH.0、GPIOI.0。而中断线每次只能连接到1个IO口上，这样就需要通过配置来决定对应的中断线配置到哪个GPIO上了。GPIO跟中断线的映射关系如 @figure-3-3 所示。

#figure(
  image("assets/image-2.png"),
  caption: [GPIO中断线映射],
)<figure-3-3>
#pagebreak()
== 实验步骤
=== 程序流程图
程序启动后首先进行系统初始化，包括HAL库初始化、系统时钟配置、GPIO外设初始化和TIM3定时器初始化。初始化完成后，程序进入主循环，执行三种不同优先级的任务。

在正常状态下，程序通过74HC595移位寄存器和74HC138译码器控制数码管显示0-9的循环计数，每秒更新一次数字。当检测到PB12按键按下时，触发外部中断，主循环暂停数码管显示任务，转而执行交通灯闪烁任务。该任务控制两组交通灯（R1-Y1-G1和R2-Y2-G2）以250毫秒为间隔交替闪烁，持续3秒后自动结束并返回正常显示。

当PB9按键按下时，触发更高优先级的中断。此时无论系统处于何种状态，都会立即响应PB9中断。如果PB12的交通灯任务正在执行，系统会保存其当前状态和已经过的时间，然后暂停该任务。接着执行LED顺序点亮任务，8个LED（PF0-PF7）依次点亮，每个LED点亮间隔100毫秒，全部点亮后保持1秒。LED任务完成后，如果之前PB12任务被中断，系统会根据保存的状态信息恢复PB12任务，继续执行剩余时间的交通灯闪烁，实现了任务的抢占与恢复机制。

所有任务执行期间，数码管的计数器会暂停，确保中断任务完成后能够继续正常计数，避免时间混乱。整个程序通过状态标志位和时间戳来协调不同任务的执行，实现了基于中断的多任务调度。

具体流程图如 @figure-3-4 所示。
#figure(
  oxdraw(
    "
  graph TD
    Start([程序开始]) --> Init[系统初始化<br/>HAL_Init<br/>SystemClock_Config]
    Init --> PeriphInit[外设初始化<br/>GPIO_Init<br/>TIM3_Init]
    PeriphInit --> StartTIM[启动TIM3定时器]
    StartTIM --> MainLoop{主循环}

    MainLoop --> CheckPB9{检查PB9中断<br/>标志位}
    CheckPB9 -->|活跃| LED_Task[LED顺序点亮任务<br/>每100ms点亮一个<br/>共8个LED]
    LED_Task --> LED_Check{是否达到<br/>1.8秒?}
    LED_Check -->|否| MainLoop
    LED_Check -->|是| LED_End[关闭所有LED<br/>清除PB9标志]
    LED_End --> CheckPreempt{PB12被<br/>抢占?}
    CheckPreempt -->|是| RestorePB12[恢复PB12任务<br/>继续剩余时间]
    CheckPreempt -->|否| MainLoop
    RestorePB12 --> MainLoop

    CheckPB9 -->|不活跃| CheckPB12{检查PB12中断<br/>标志位}
    CheckPB12 -->|活跃| Traffic_Task[交通灯闪烁任务<br/>两组灯交替闪烁<br/>250ms间隔]
    Traffic_Task --> Traffic_Check{是否达到<br/>3秒?}
    Traffic_Check -->|否| MainLoop
    Traffic_Check -->|是| Traffic_End[关闭所有交通灯<br/>清除PB12标志]
    Traffic_End --> MainLoop

    CheckPB12 -->|不活跃| NormalTask[正常任务<br/>数码管显示0-9循环<br/>每秒更新一次]
    NormalTask --> MainLoop

    INT_PB12[PB12按键中断] -.->|触发| PB12_ISR[设置PB12标志位<br/>记录开始时间<br/>关闭LED]
    PB12_ISR -.-> MainLoop

    INT_PB9[PB9按键中断] -.->|触发| PB9_ISR[设置PB9标志位<br/>记录开始时间<br/>关闭交通灯]
    PB9_ISR --> SavePB12{PB12正在<br/>执行?}
    SavePB12 -->|是| SaveState[保存PB12状态<br/>暂停PB12任务]
    SavePB12 -->|否| ClearLights[清除所有输出]
    SaveState --> ClearLights
    ClearLights -.-> MainLoop
  "),
)<figure-3-4>
=== 程序清单
+ GPIO配置

  ```c
  void MX_GPIO_Init(void)
  {
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    /* GPIO时钟使能 */
    __HAL_RCC_GPIOC_CLK_ENABLE();  // 使能GPIOC时钟，用于74HC595和74HC138控制
    __HAL_RCC_GPIOF_CLK_ENABLE();  // 使能GPIOF时钟，用于LED和交通灯
    __HAL_RCC_GPIOH_CLK_ENABLE();  // 使能GPIOH时钟
    __HAL_RCC_GPIOB_CLK_ENABLE();  // 使能GPIOB时钟，用于按键中断

    /* 配置GPIOF输出引脚（LED和交通灯） */
    GPIO_InitStruct.Pin = GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_2|GPIO_PIN_3
                        |GPIO_PIN_4|GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7
                        |GPIO_PIN_8|GPIO_PIN_9|GPIO_PIN_10|GPIO_PIN_11
                        |GPIO_PIN_12|GPIO_PIN_13;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;      // 推挽输出模式
    GPIO_InitStruct.Pull = GPIO_NOPULL;              // 无上下拉
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;     // 低速
    HAL_GPIO_Init(GPIOF, &GPIO_InitStruct);

    /* 配置GPIOC输出引脚（74HC595和74HC138控制） */
    GPIO_InitStruct.Pin = GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_2|GPIO_PIN_3
                        |GPIO_PIN_4|GPIO_PIN_5;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
    HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);

    /* 配置GPIOB中断引脚（PB12和PB9） */
    GPIO_InitStruct.Pin = GPIO_PIN_12|GPIO_PIN_9;
    GPIO_InitStruct.Mode = GPIO_MODE_IT_RISING;      // 上升沿触发中断
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

    /* EXTI中断配置 */
    HAL_NVIC_SetPriority(EXTI9_5_IRQn, 0, 0);        // PB9中断最高优先级
    HAL_NVIC_EnableIRQ(EXTI9_5_IRQn);                // 使能EXTI9_5中断

    HAL_NVIC_SetPriority(EXTI15_10_IRQn, 0, 0);      // PB12中断优先级
    HAL_NVIC_EnableIRQ(EXTI15_10_IRQn);              // 使能EXTI15_10中断
  }
  ```
+ 定时器配置

  ```c
  void MX_TIM3_Init(void)
  {
    TIM_ClockConfigTypeDef sClockSourceConfig = {0};
    TIM_MasterConfigTypeDef sMasterConfig = {0};

    /* TIM3基本配置 */
    htim3.Instance = TIM3;                           // 使用TIM3
    htim3.Init.Prescaler = 0;                        // 预分频器为0
    htim3.Init.CounterMode = TIM_COUNTERMODE_UP;     // 向上计数模式
    htim3.Init.Period = 65535;                       // 自动重装载值
    htim3.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
    htim3.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
    
    /* 初始化定时器基础功能 */
    if (HAL_TIM_Base_Init(&htim3) != HAL_OK)
    {
      Error_Handler();
    }
    
    /* 配置时钟源 */
    sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
    if (HAL_TIM_ConfigClockSource(&htim3, &sClockSourceConfig) != HAL_OK)
    {
      Error_Handler();
    }
  }
  ```
+ 主程序

  ```c
  /* 引脚定义 */
  #define SI_PIN GPIO_PIN_0       // 74HC595数据输入
  #define RCK_PIN GPIO_PIN_1      // 74HC595锁存时钟
  #define SCK_PIN GPIO_PIN_2      // 74HC595移位时钟
  #define A_PIN GPIO_PIN_3        // 74HC138地址线A
  #define B_PIN GPIO_PIN_4        // 74HC138地址线B
  #define C_PIN GPIO_PIN_5        // 74HC138地址线C

  /* 全局变量 */
  const uint8_t digit_codes[10] = {
      0x3F, 0x06, 0x5B, 0x4F, 0x66,  // 数码管段码：0-4
      0x6D, 0x7D, 0x07, 0x7F, 0x6F   // 数码管段码：5-9
  };

  volatile uint8_t current_digit = 0;              // 当前显示数字
  volatile uint32_t last_update_time = 0;          // 上次更新时间
  volatile uint8_t pb12_interrupt_active = 0;      // PB12中断活跃标志
  volatile uint8_t pb9_interrupt_active = 0;       // PB9中断活跃标志
  volatile uint32_t interrupt_start_time = 0;      // 中断开始时间
  volatile uint8_t pb12_was_preempted = 0;         // PB12被抢占标志
  volatile uint32_t pb12_elapsed_before_preempt = 0; // PB12被抢占前的已用时间

  /* 74HC595发送字节函数 */
  void HC595_SendByte(uint8_t data) {
      HAL_GPIO_WritePin(RCK_PORT, RCK_PIN, GPIO_PIN_RESET); // 拉低锁存时钟
      
      for (int i = 7; i >= 0; i--) {                        // 发送8位数据，MSB优先
          HAL_GPIO_WritePin(SCK_PORT, SCK_PIN, GPIO_PIN_RESET);
          
          if (data & (1 << i)) {
              HAL_GPIO_WritePin(SI_PORT, SI_PIN, GPIO_PIN_SET);
          } else {
              HAL_GPIO_WritePin(SI_PORT, SI_PIN, GPIO_PIN_RESET);
          }
          
          HAL_GPIO_WritePin(SCK_PORT, SCK_PIN, GPIO_PIN_SET); // 上升沿锁存数据
      }
      
      HAL_GPIO_WritePin(RCK_PORT, RCK_PIN, GPIO_PIN_SET);   // 输出到并行口
  }

  /* 交通灯闪烁任务 */
  void Traffic_Light_Task(void) {
      uint32_t elapsed = HAL_GetTick() - interrupt_start_time;
      
      if (elapsed >= 3000) {                                // 3秒后结束
          HAL_GPIO_WritePin(TRAFFIC_PORT, R1_PIN | Y1_PIN | G1_PIN | 
                          R2_PIN | Y2_PIN | G2_PIN, GPIO_PIN_RESET);
          pb12_interrupt_active = 0;
          return;
      }
      
      uint32_t phase = (elapsed / 250) % 2;                 // 250ms周期交替
      
      if (phase == 0) {
          HAL_GPIO_WritePin(TRAFFIC_PORT, R1_PIN | Y1_PIN | G1_PIN, GPIO_PIN_SET);
          HAL_GPIO_WritePin(TRAFFIC_PORT, R2_PIN | Y2_PIN | G2_PIN, GPIO_PIN_RESET);
      } else {
          HAL_GPIO_WritePin(TRAFFIC_PORT, R1_PIN | Y1_PIN | G1_PIN, GPIO_PIN_RESET);
          HAL_GPIO_WritePin(TRAFFIC_PORT, R2_PIN | Y2_PIN | G2_PIN, GPIO_PIN_SET);
      }
  }

  /* LED顺序点亮任务 */
  void LED_Sequential_Task(void) {
      uint32_t elapsed = HAL_GetTick() - interrupt_start_time;
      
      if (elapsed >= 1800) {                                // 1.8秒后结束
          HAL_GPIO_WritePin(LED_PORT, 0xFF, GPIO_PIN_RESET);
          pb9_interrupt_active = 0;
          
          if (pb12_was_preempted) {                         // 恢复被抢占的PB12任务
              pb12_interrupt_active = 1;
              pb12_was_preempted = 0;
              interrupt_start_time = HAL_GetTick() - pb12_elapsed_before_preempt;
          }
          return;
      }
      
      uint8_t led_count = elapsed / 100;                    // 每100ms点亮一个LED
      
      if (led_count >= 8) {                                 // 全部点亮后保持
          HAL_GPIO_WritePin(LED_PORT, 0xFF, GPIO_PIN_SET);
          return;
      }
      
      uint16_t led_mask = 0;
      for (uint8_t i = 0; i <= led_count; i++) {
          led_mask |= (1 << i);
      }
      
      HAL_GPIO_WritePin(LED_PORT, 0xFF, GPIO_PIN_RESET);
      HAL_GPIO_WritePin(LED_PORT, led_mask, GPIO_PIN_SET);
  }

  /* 主函数 */
  int main(void)
  {
    HAL_Init();                    // HAL库初始化
    SystemClock_Config();          // 系统时钟配置
    MX_GPIO_Init();                // GPIO初始化
    MX_TIM3_Init();                // TIM3初始化
    
    HAL_TIM_Base_Start(&htim3);    // 启动TIM3定时器
    last_update_time = HAL_GetTick();

    while (1)
    {
      if (pb9_interrupt_active) {                     // PB9中断最高优先级
          LED_Sequential_Task();
          last_update_time = HAL_GetTick();
          continue;
      }
      
      if (pb12_interrupt_active) {                    // PB12中断次优先级
          Traffic_Light_Task();
          last_update_time = HAL_GetTick();
          continue;
      }
      
      /* 正常任务：数码管显示0-9循环 */
      uint32_t current_time = HAL_GetTick();
      if (current_time - last_update_time >= 1000) {  // 每秒更新
          current_digit++;
          if (current_digit > 9) {
              current_digit = 0;
          }
          last_update_time = current_time;
      }
      
      Display_Digit(current_digit);                   // 显示当前数字
    }
  }

  /* GPIO中断回调函数 */
  void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin) {
      if (GPIO_Pin == GPIO_PIN_12) {                  // PB12按键中断
          if (!pb9_interrupt_active && !pb12_was_preempted) {
              pb12_interrupt_active = 1;
              interrupt_start_time = HAL_GetTick();
              HAL_GPIO_WritePin(LED_PORT, 0xFF, GPIO_PIN_RESET);
          }
      } else if (GPIO_Pin == GPIO_PIN_9) {            // PB9按键中断
          pb9_interrupt_active = 1;
          
          if (pb12_interrupt_active) {                // 抢占PB12任务
              pb12_was_preempted = 1;
              pb12_elapsed_before_preempt = HAL_GetTick() - interrupt_start_time;
              pb12_interrupt_active = 0;
          }
          
          interrupt_start_time = HAL_GetTick();
          HAL_GPIO_WritePin(TRAFFIC_PORT, R1_PIN | Y1_PIN | G1_PIN | 
                          R2_PIN | Y2_PIN | G2_PIN, GPIO_PIN_RESET);
          HAL_GPIO_WritePin(LED_PORT, 0xFF, GPIO_PIN_RESET);
      }
  }
  ```
=== 实现方式
本实验采用#highlight[外部中断（EXTI）方式]实现按键触发的中断响应机制。具体实现包括以下几个关键要素。

首先是硬件中断配置，通过将PB9和PB12两个GPIO引脚配置为外部中断模式（`GPIO_MODE_IT_RISING`），设置为上升沿触发。在NVIC中断控制器中，PB9对应EXTI9_5中断线，PB12对应EXTI15_10中断线，两者都配置为最高优先级（抢占优先级0，子优先级0）。

中断服务程序采用HAL库的标准处理流程。当按键按下产生上升沿时，硬件自动触发对应的中断服务函数（`EXTI9_5_IRQHandler或EXTI15_10_IRQHandler`），这些函数调用`HAL_GPIO_EXTI_IRQHandler`进行中断标志清除和事件分发，最终回调到用户定义的`HAL_GPIO_EXTI_Callback`函数。

在回调函数中，程序通过判断GPIO_Pin参数来区分是哪个按键触发了中断，然后设置相应的任务标志位（`pb9_interrupt_active`或`pb12_interrupt_active`），记录中断触发时间戳，并进行必要的状态保存。主循环通过轮询这些标志位来执行相应的任务处理函数。

本实验还实现了软件层面的任务抢占机制。当PB9中断发生时，如果PB12任务正在执行，程序会保存PB12的执行状态和已用时间，暂停其执行，优先处理PB9任务。PB9任务完成后，再根据保存的信息恢复PB12任务的执行，实现了中断嵌套和任务调度的功能。这种实现方式结合了硬件中断的快速响应和软件任务调度的灵活性，适合处理多优先级的实时任务。
== 实验总结
通过本次实验，我深入理解了STM32单片机的中断机制和多任务处理方法。在实际编程过程中，我体会到中断响应速度快、实时性强的特点，同时也认识到必须谨慎处理中断嵌套和任务切换时的状态保存问题。特别是在实现PB9抢占PB12任务时，需要精确记录时间戳和任务状态，确保任务恢复后能够继续正确执行。这让我明白了嵌入式系统开发中，时序控制和状态管理的重要性，也锻炼了我在复杂逻辑下的调试能力。

此外，实验中使用74HC595和74HC138等外围芯片控制数码管和LED，加深了我对硬件接口和时序协议的理解。在调试过程中遇到的数码管显示闪烁、LED点亮不同步等问题，都通过分析时序图和逻辑分析得到了解决。这次实验不仅提升了我的硬件编程能力，也培养了系统性思考问题的习惯，为今后开发更复杂的嵌入式应用打下了坚实基础。

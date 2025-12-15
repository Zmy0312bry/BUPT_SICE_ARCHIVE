#import "@preview/basic-report:0.3.1": *
#import "@preview/oxdraw:0.1.0": *

#show: it => basic-report(
  doc-category: "计算机原理",
  doc-title: "流水灯实验报告",
  author: "XXX 2023210XXX",
  affiliation: "20232111XX, 信息与通信工程学院, 北京邮电大学",
  logo: image("assets/bupt-logo.jpg", width: 3cm),
  language: "zh",
  heading-font: "Maple Mono NF",
  compact-mode: false,
  // show-outline: false,
  it,
)

= 实验一 流水灯实验报告
== 实验目的
1. 掌握流水灯驱动原理。
2. 掌握基本IO的使用。
== 实验要求
设计并实现一个流水灯系统，具体要求如下：

系统上电时，八个LED灯从左至右间隔100ms依次点亮,类似流水效果,前一个LED灯点亮然后熄灭时点亮下一个LED灯,循环往复。
== 实验原理
电路结构如 @figure-1-1 所示。
#figure(
  image("assets/image.png"),
  caption: "电路结构",
)<figure-1-1>
接线：GPIOF_0\~GPIOF_7(P12接口)接LED_1\~LED_8(P2接口)

=== 硬件原理
LED灯驱动原理，如 @figure-1-2 所示，发光二极管正向导通LED灯点亮。
#figure(
  image("assets/image-1.png"),
  caption: "LED灯正向导通图示",
)<figure-1-2>
如 @figure-1-3 所示LED灯与MCU引脚连接，MCU IO额定电流为25mA，例如0603封装红色LED灯额定电流为20mA，已经接近MCU IO的额定电流，可能会损毁器件。因此上图微控制器驱动LED灯方案不可取。
#figure(
  image("assets/image-2.png"),
  caption: "微控制器驱动LED灯",
)<figure-1-3>
实际微控制驱动LED灯的电路模型包括：控制器、驱动器和执行器三部分，控制器提供控制信号，再由驱动器驱动执行器，如 @figure-1-4 所示。
#figure(
  image("assets/image-3.png", width: 11.5cm),
  caption: "LED灯驱动电路模型",
)<figure-1-4>
如 @figure-1-5 所示LED灯通过N沟道MOS管驱动，MCU IO输出高电平时MOS管漏极和源极导通LED灯被点亮，反之MCU输出低电平时MOS管漏极和源极截止，LED灯不能被点亮。假设VCC电压3.3V，MOS管导通阻值为零，通过LED灯的电流将远超额定电流出现短路现象，故此方案不可取。
#figure(
  image("assets/image-4.png", width: 5cm),
  caption: "MOS管驱动LED灯电路",
)<figure-1-5>
如 @figure-1-6 所示，LED驱动电路中增加电阻R，以此保证通过LED灯的电流不超过额定电流，避免损坏器件，故将电阻R称为限流电阻。
#figure(
  image("assets/image-5.png"),
  caption: "限流电阻",
)<figure-1-6>
如 @figure-1-7 所示LED电路原理图，R1位置电阻作为限流电阻，R29位置电阻作为下拉电阻，避免MOS管栅极出现亚稳态。
#figure(
  image("assets/image-6.png"),
  caption: "LED电路原理图",
)<figure-1-7>
=== 微控制器IO输出控制原理
==== 基本结构
基本结构针对STM32F407有7组IO。分别为GPIOA\~GPIOG，每组IO有16个IO口，则有112个IO口。
#figure(
  image("assets/image-7.png"),
  caption: "STM32F4基本I/O端口结构",
)<figure-1-8>
==== 工作方式
STM32F4工作模式有8种，当中4中输入模式。4种输出模式，分别为：输入浮空、输入上拉、输入下拉、模拟模式、开漏输出、开漏复用输出、推挽输出、推挽复用输出。
- 输入模式：

  输入浮空模式下。电路既不上拉也不下拉，通过施密特触发器送到输入数据寄存器在送入到CPU。输入上拉和下拉模式各自是在电路中经过上拉和下拉后通过施密特触发器送入的CPU，模拟模式下，施密特触发器关闭后信号直接通过模拟通道至片上外设。
- 输出模式：

  开漏输出模式下。CPU发送输入直接或间接的控制输出数据寄存器，通过输出控制电路，当信号为1时，N—MOS管是关闭的，所以IO电平就是受上下拉电路的控制。当信号为0时。N—MOS管导通输出就是下拉低电平；推挽输出模式下。信号为1时，P-MOS管导通，N-MOS管截止，输出就是上拉高电平，当信号为0时。P-MOS管截止，N-MOS管导通。输出就是下拉低电平；对于开漏复用和推挽复用模式与开漏和推挽的不同之处就是在于信号的开源不同。开漏复用和推挽复用的信号来源是片上的外设模块。
==== 相关寄存器
每个通用的IOport都包含4个32位的配置寄存器（GPIOx_MODER、GPIOx_OTYPER、PIOx_OSPEEDR和GPIOx_PUPDR）。2个32位的数据寄存器（GPIOx_IDR和GPIOx_ODR），1个32位置位/复位寄存器（GPIOx_BSRR），1个32位锁定寄存器（GPIOx_LCKR）和2个32位复用功能选择寄存器（GPIOx_AFRL）。
+ 工作模式配置：port模式（GPIOx_MODER）：用来配置port的模式为输入、输出、复用和模拟模式。port类型（GPIOx_OTYPER）：用来配置寄存器的模式为输出推挽还是输出开漏。port速度（PIOx_OSPEEDR）：用来配置port的信息传输速率。port上下拉（GPIOx_PUPDR）：用来配置port的无上下拉、上拉、下拉和保留模式。
+ 电平配置：输入数据（GPIOx_IDR）：用到其低16位。分别对应该组IO口的一个电平状态。输出数据（GPIOx_ODR）：与输入数据寄存器相似的功能。置位和复位（GPIOx_BSRR）：与前两个不同的是置位和复位寄存器用到了32位。低16为设置为1时，用于置1对应位。高16位设置为1时，用于置0对应位。而低16位和高16位设置为0时不影响原值。

=== 微控制器IO输出配置过程
由电路原理图可知若点亮LED灯微控制器需要输出高电平。若使LED灯闪烁只需将微控制器对应IO口电平循环翻转即可实现。

要使用基本I/O端口来驱动点亮LED灯就需要将端口进行初始化配置，对端口配置之前必须开启该端口的时钟，然后选择引脚、端口模式、端口输出速度（为输出模式时才需要设置），配置完成后需要调用端口初始化函数，将端口初始化，若端口初始状态需要固定，可以在初始化端口过后，给端口赋初值。

GPIO配置过程如下:
+ 开启端口时钟。开启时钟时需要注意端口时钟在哪一个AHB分频器下，选对AHB才能正确开启端口时钟。
+ 选择引脚。通常在配置端口时，只需要配置需要使用的引脚即可。
+ 选择端口模式。I/O端口即输入输出端口，在不同情况下需要的功能不同，可以选择配置成输出模式、输入模式或是模拟输入模式。
+ 选择端口输出速度。端口的速度只有在输出模式时才需要配置，决定数据输出的速度。
+ 端口初始化。只有进行端口初始化端口配置才算完成。
+ 端口赋初值。输出模式时才需要。若是没有对端口进行初值赋值，在上电复位时端口状态是随机的，在很多情况下需要对端口进行初值赋值，使端口上电复位时输出固定状态。
#pagebreak()
== 实验步骤
=== 程序流程图

1. 系统初始化流程

  系统启动后首先调用 `HAL_Init()` 初始化HAL库，配置系统基础功能。然后通过 `SystemClock_Config()` 配置系统时钟，使用HSI内部时钟源（16MHz），经过PLL倍频得到84MHz系统时钟，APB1和APB2总线频率均为42MHz，定时器时钟为84MHz（APB时钟自动倍频）。

  接着进行GPIO初始化 `MX_GPIO_Init()`，将GPIOF (PF0~PF13) 配置为输出模式用于控制LED和交通灯，GPIOC (PC0~PC5) 配置为输出模式用于74HC595和74HC138控制信号，GPIOB (PB9, PB12) 配置为外部中断模式（上升沿触发）用于按键检测。

  随后初始化定时器TIM3 `MX_TIM3_Init()`，设置预分频器为8399（将84MHz分频为10kHz），自动重装载值为999（将10kHz分频为10Hz），最终得到10Hz的中断频率（每100ms触发一次）。

  最后调用 `HAL_TIM_Base_Start_IT(&htim3)` 启动定时器中断，使能周期性触发。完成初始化后进入主循环 `while(1)`，主循环体为空，所有功能由中断驱动，CPU可以在主循环中进入低功耗模式或处理其他任务。

2. 定时器中断处理流程

  TIM3定时器每100ms触发一次中断，系统自动调用 `HAL_TIM_PeriodElapsedCallback()` 函数处理。进入中断后首先执行 `timer_counter++` 实现软件分频计数。

  然后判断 `timer_counter >= speed_divider` 是否成立，如果未达到则直接返回等待下次中断；如果达到则将 `timer_counter` 清零，并依次调用三个任务。所有任务完成后退出中断返回主循环。

  通过这种软件分频机制，基础中断频率为10Hz（每100ms），实际更新频率 = 10Hz ÷ speed_divider。speed_divider取值范围为2~50，对应实际频率范围为0.2Hz ~ 5Hz，实现了灵活的速度控制。

  - 任务1：数码管流水灯流程

    `Update_SegmentLight()` 函数首先从变量 `segment_pos`（范围0-5）读取当前要点亮的段位置，然后从 `segment_patterns[]` 数组获取对应的段码（0x01~0x20分别对应a~f段），每个段码只点亮一个段以形成流水效果。

    获取段码后调用 `Display_Segment(段码, 0)` 将数据显示到第0位数码管。在此函数内部，先通过 `HC595_SendByte()` 将段码发送到74HC595芯片：拉低RCK准备接收数据，循环8次从高位到低位发送（每次拉低SCK设置SI数据位后拉高SCK移入数据），最后拉高RCK锁存输出。同时通过设置PC3(A)、PC4(B)、PC5(C)控制74HC138译码器选择数码管位置。

    完成显示后执行 `segment_pos++` 移动到下一段，当 `segment_pos >= 6` 时回到0重新循环，从而实现6个段依次点亮的流水灯效果。

  - 任务2：交通灯控制流程

    `Update_TrafficLight()` 函数采用简单的二状态机控制两组交通灯交替闪烁。函数读取 `traffic_state` 变量判断当前状态，若为状态0则将第一组灯（PF8红1、PF9黄1、PF10绿1）全部点亮，第二组灯（PF11红2、PF12黄2、PF13绿2）全部熄灭，然后切换到状态1。

    若为状态1则执行相反操作：第一组灯全部熄灭，第二组灯全部点亮，然后切换回状态0。这样每次调用函数时两组灯的状态都会对调，形成交替闪烁的流水效果。整个过程实现简单但视觉效果明显。

  - 任务3：LED流水灯流程

    `Update_LEDLight()` 函数通过双模式设计实现LED依次点亮再依次熄灭的效果。函数读取 `led_mode` 变量判断当前处于点亮模式（0）还是熄灭模式（1）。

    在点亮模式下，通过 `HAL_GPIO_WritePin(GPIOF, 1<<led_pos, HIGH)` 点亮当前位置的LED（PF0~PF7对应LED1~LED8，使用位移操作选择），然后 `led_pos++` 移动到下一个LED。当 `led_pos >= 8` 时说明8个LED全部点亮完毕，此时将 `led_pos` 重置为0并切换到熄灭模式。

    在熄灭模式下，执行类似操作但调用 `HAL_GPIO_WritePin(GPIOF, 1<<led_pos, LOW)` 熄灭LED，同样 `led_pos++` 移动位置。当 `led_pos >= 8` 时8个LED全部熄灭完毕，重置 `led_pos` 为0并切换回点亮模式。这样循环往复，形成LED1→LED2→...→LED8依次点亮，再依次熄灭的流水灯效果。

3. 按钮中断处理流程

  当按键按下时GPIO引脚检测到上升沿触发外部中断，系统自动调用 `HAL_GPIO_EXTI_Callback(GPIO_Pin)` 函数并传入触发中断的引脚号。函数内部通过判断引脚号来区分不同按键，再根据不同按键执行相应操作。

  通过这种方式，speed_divider在2~50范围内调节，对应最快频率5Hz（200ms周期）和最慢频率0.2Hz（5s周期），实现了灵活的速度控制。
4. 流程图 如 @figure-1-9 所示。
#figure(
  oxdraw(
    "
graph TD
    A[系统启动] --> B[HAL_Init 初始化HAL库]
    B --> C[SystemClock_Config 配置系统时钟]
    C --> D[MX_GPIO_Init 初始化GPIO]
    D --> E[MX_TIM3_Init 初始化定时器TIM3]
    E --> F[HAL_TIM_Base_Start_IT 启动定时器中断]
    F --> G[进入主循环 while1]

    G --> H{定时器中断触发<br/>每100ms}
    H --> I[timer_counter++]
    I --> J{counter >= speed_divider?}
    J -->|否| G
    J -->|是| K[timer_counter = 0]

    K --> L[Update_SegmentLight<br/>更新数码管流水灯]
    K --> M[Update_TrafficLight<br/>更新交通灯]
    K --> N[Update_LEDLight<br/>更新LED流水灯]

    L --> G
    M --> G
    N --> G

    G --> O{按键中断触发}
    O -->|PB9| P[speed_divider -= 2<br/>提高频率]
    O -->|PB12| Q[speed_divider += 2<br/>降低频率]
    P --> G
    Q --> G
",
  ),
  caption: "程序流程图",
)<figure-1-9>

=== 程序清单

+ 主要硬件配置参数

  ```c
  // GPIO引脚配置
  // LED1~8:        GPIOF, PIN 0~7    (输出模式，高电平点亮)
  // 交通灯组1:     GPIOF, PIN 8~10   (红1,黄1,绿1)
  // 交通灯组2:     GPIOF, PIN 11~13  (红2,黄2,绿2)
  // 74HC595控制:   GPIOC, PIN 0~2    (SI, RCK, SCK)
  // 74HC138控制:   GPIOC, PIN 3~5    (A, B, C)
  // 按钮1:         GPIOB, PIN 9      (外部中断，上升沿触发)
  // 按钮2:         GPIOB, PIN 12     (外部中断，上升沿触发)

  // 定时器TIM3配置
  // 时钟源：       APB1定时器时钟 = 84MHz
  // 预分频器：     8399  → 84MHz / 8400 = 10kHz
  // 自动重装载值： 999   → 10kHz / 1000 = 10Hz
  // 中断频率：     10Hz (每100ms触发一次)
  ```

+ 全局变量定义

  ```c
  /* USER CODE BEGIN PV */
  // ========== 全局变量定义 ==========

  // 定时器计数器
  volatile uint32_t timer_counter = 0;

  // 频率控制变量 (基础周期倍数)
  // 范围：2~50，控制实际更新频率
  // 实际频率 = 10Hz / speed_divider
  volatile uint32_t speed_divider = 10; // 初始速度：1Hz

  // 数码管流水灯变量 (8段: a,b,c,d,e,f,g,dp)
  volatile uint8_t segment_pos = 0; // 当前亮的段位置 (0-7)

  // 交通灯状态变量
  volatile uint8_t traffic_state = 0; // 0: 灯组1亮, 1: 灯组2亮

  // LED流水灯变量
  volatile uint8_t led_mode = 0; // 0: 依次点亮, 1: 依次熄灭
  volatile uint8_t led_pos = 0;  // 当前LED位置 (0-7)

  // 段码定义 (只点亮单个段，用于流水灯效果)
  const uint8_t segment_patterns[8] = {
      0x01, // 第0位：a段
      0x02, // 第1位：b段
      0x04, // 第2位：c段
      0x08, // 第3位：d段
      0x10, // 第4位：e段
      0x20, // 第5位：f段
      // 注释掉的g段和dp段不使用
      // 0x40, // g段
      // 0x80  // dp段
  };
  /* USER CODE END PV */
  ```

+ 核心函数实现

  + HC595_SendByte - 74HC595串行数据发送

    *功能说明*：通过SPI协议向74HC595移位寄存器芯片发送8位数据

    *参数*：
    - `data`: 要发送的8位段码数据

    *实现原理*：
    1. 拉低RCK，准备数据传输
    2. 循环8次，从高位到低位依次发送
    3. 每次发送：SCK拉低 → 设置SI数据位 → SCK拉高（移入数据）
    4. 拉高RCK，将移位寄存器数据锁存到输出端

    ```c
    /*
     * @brief 通过74HC595发送一个字节数据
     * @param data 要发送的8位数据
     */
    void HC595_SendByte(uint8_t data)
    {
        // 拉低RCK，准备传输
        HAL_GPIO_WritePin(GPIOC, GPIO_PIN_1, GPIO_PIN_RESET); // RCK = 0

        // 从高位到低位发送8位数据
        for(int i = 7; i >= 0; i--)
        {
            // 拉低SCK（时钟信号准备）
            HAL_GPIO_WritePin(GPIOC, GPIO_PIN_2, GPIO_PIN_RESET); // SCK = 0

            // 设置SI数据线（串行输入）
            if(data & (1 << i))  // 检查第i位是否为1
                HAL_GPIO_WritePin(GPIOC, GPIO_PIN_0, GPIO_PIN_SET);    // SI = 1
            else
                HAL_GPIO_WritePin(GPIOC, GPIO_PIN_0, GPIO_PIN_RESET);  // SI = 0

            // 拉高SCK，移入数据到移位寄存器
            HAL_GPIO_WritePin(GPIOC, GPIO_PIN_2, GPIO_PIN_SET); // SCK = 1
        }

        // 拉高RCK，锁存数据到输出端
        HAL_GPIO_WritePin(GPIOC, GPIO_PIN_1, GPIO_PIN_SET); // RCK = 1
    }
    ```

  + Display_Segment - 显示数码管段

    *功能说明*：将段码数据发送到74HC595，并通过74HC138选择数码管位

    *参数*：
    - `segment_code`: 段码数据（8位，对应a~g和dp）
    - `digit_pos`: 数码管位选（0~7）

    ```c
    /*
     * @brief 显示数码管的某一位
     * @param segment_code 段码
     * @param digit_pos 位选 (0-7)
     */
    void Display_Segment(uint8_t segment_code, uint8_t digit_pos)
    {
        // 通过74HC595发送段码
        HC595_SendByte(segment_code);

        // 通过74HC138选择数码管位 (ABC控制)
        // A=PC3, B=PC4, C=PC5
        // 将digit_pos的二进制位分别输出到A, B, C
        if(digit_pos & 0x01)  // 检查第0位
            HAL_GPIO_WritePin(GPIOC, GPIO_PIN_3, GPIO_PIN_SET);
        else
            HAL_GPIO_WritePin(GPIOC, GPIO_PIN_3, GPIO_PIN_RESET);

        if(digit_pos & 0x02)  // 检查第1位
            HAL_GPIO_WritePin(GPIOC, GPIO_PIN_4, GPIO_PIN_SET);
        else
            HAL_GPIO_WritePin(GPIOC, GPIO_PIN_4, GPIO_PIN_RESET);

        if(digit_pos & 0x04)  // 检查第2位
            HAL_GPIO_WritePin(GPIOC, GPIO_PIN_5, GPIO_PIN_SET);
        else
            HAL_GPIO_WritePin(GPIOC, GPIO_PIN_5, GPIO_PIN_RESET);
    }
    ```

  + Update_SegmentLight - 更新数码管流水灯

    *功能说明*：控制数码管单段依次点亮，形成流水灯效果

    ```c
    /*
     * @brief 更新数码管流水灯
     */
    void Update_SegmentLight(void)
    {
        // 显示当前段（第0位数码管）
        Display_Segment(segment_patterns[segment_pos], 0);

        // 移动到下一段
        segment_pos++;
        if(segment_pos >= 6)  // 只使用6段（a~f）
            segment_pos = 0;  // 循环
    }
    ```

  + Update_TrafficLight - 更新交通灯状态

    *功能说明*：控制两组交通灯交替闪烁

    ```c
    /*
     * @brief 更新交通灯状态
     */
    void Update_TrafficLight(void)
    {
        if(traffic_state == 0)
        {
            // 状态0：第一组灯亮 (红1, 黄1, 绿1) = (PF8, PF9, PF10)
            HAL_GPIO_WritePin(GPIOF, GPIO_PIN_8, GPIO_PIN_SET);   // 红1亮
            HAL_GPIO_WritePin(GPIOF, GPIO_PIN_9, GPIO_PIN_SET);   // 黄1亮
            HAL_GPIO_WritePin(GPIOF, GPIO_PIN_10, GPIO_PIN_SET);  // 绿1亮

            // 第二组灯灭 (红2, 黄2, 绿2) = (PF11, PF12, PF13)
            HAL_GPIO_WritePin(GPIOF, GPIO_PIN_11, GPIO_PIN_RESET); // 红2灭
            HAL_GPIO_WritePin(GPIOF, GPIO_PIN_12, GPIO_PIN_RESET); // 黄2灭
            HAL_GPIO_WritePin(GPIOF, GPIO_PIN_13, GPIO_PIN_RESET); // 绿2灭

            traffic_state = 1;  // 切换到状态1
        }
        else
        {
            // 状态1：第一组灯灭
            HAL_GPIO_WritePin(GPIOF, GPIO_PIN_8, GPIO_PIN_RESET);
            HAL_GPIO_WritePin(GPIOF, GPIO_PIN_9, GPIO_PIN_RESET);
            HAL_GPIO_WritePin(GPIOF, GPIO_PIN_10, GPIO_PIN_RESET);

            // 第二组灯亮
            HAL_GPIO_WritePin(GPIOF, GPIO_PIN_11, GPIO_PIN_SET);
            HAL_GPIO_WritePin(GPIOF, GPIO_PIN_12, GPIO_PIN_SET);
            HAL_GPIO_WritePin(GPIOF, GPIO_PIN_13, GPIO_PIN_SET);

            traffic_state = 0;  // 切换到状态0
        }
    }
    ```

  + Update_LEDLight - 更新LED流水灯

    *功能说明*：控制8个LED先依次点亮，再依次熄灭

    ```c
    /*
     * @brief 更新LED流水灯
     */
    void Update_LEDLight(void)
    {
        if(led_mode == 0) // 模式0: 依次点亮
        {
            // 点亮当前LED (PF0-PF7对应LED1-LED8)
            // 使用位移操作: 1<<0=0x01, 1<<1=0x02, ..., 1<<7=0x80
            HAL_GPIO_WritePin(GPIOF, 1 << led_pos, GPIO_PIN_SET);

            led_pos++;  // 移动到下一个LED
            if(led_pos >= 8)
            {
                led_pos = 0;     // 回到第一个LED
                led_mode = 1;    // 切换到熄灭模式
            }
        }
        else // 模式1: 依次熄灭
        {
            // 熄灭当前LED
            HAL_GPIO_WritePin(GPIOF, 1 << led_pos, GPIO_PIN_RESET);

            led_pos++;  // 移动到下一个LED
            if(led_pos >= 8)
            {
                led_pos = 0;     // 回到第一个LED
                led_mode = 0;    // 切换到点亮模式
            }
        }
    }
    ```

  + HAL_TIM_PeriodElapsedCallback - 定时器中断回调

    *功能说明*：定时器周期中断回调，控制任务更新频率

    ```c
    /*
     * @brief 定时器周期回调函数
     * @param htim 定时器句柄
     */
    void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
    {
        if(htim->Instance == TIM3)
        {
            timer_counter++;  // 计数器递增

            // 根据speed_divider调整更新频率
            // 例如：speed_divider=10时，每10次中断（1秒）更新一次
            if(timer_counter >= speed_divider)
            {
                timer_counter = 0;  // 计数器清零

                // 并行更新三个任务
                Update_SegmentLight();  // 数码管流水灯
                Update_TrafficLight();  // 交通灯
                Update_LEDLight();      // LED流水灯
            }
        }
    }
    ```

  + HAL_GPIO_EXTI_Callback - GPIO外部中断回调

    *功能说明*：处理按键中断，调节运行频率

    ```c
    /*
     * @brief GPIO外部中断回调函数
     * @param GPIO_Pin 触发中断的引脚号
     */
    void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin)
    {
        if(GPIO_Pin == GPIO_PIN_9) // PB9 - 按钮1: 提高频率
        {
            if(speed_divider > 2)  // 限制最小值为2
                speed_divider -= 2;  // 减小分频系数，提高频率
        }
        else if(GPIO_Pin == GPIO_PIN_12) // PB12 - 按钮2: 降低频率
        {
            if(speed_divider < 50)  // 限制最大值为50
                speed_divider += 2;  // 增大分频系数，降低频率
        }
    }
    ```

+ main函数

  *功能说明*：程序入口，完成系统初始化后进入空循环

  ```c
  int main(void)
  {
      /* 初始化HAL库 */
      HAL_Init();

      /* 配置系统时钟 */
      SystemClock_Config();

      /* 初始化所有外设 */
      MX_GPIO_Init();   // GPIO初始化
      MX_TIM3_Init();   // 定时器初始化

      /* USER CODE BEGIN 2 */
      // 启动定时器中断
      HAL_TIM_Base_Start_IT(&htim3);
      /* USER CODE END 2 */

      /* 主循环 */
      while (1)
      {
          // 主循环为空，所有功能由中断驱动
      }
  }
  ```

=== 实现方式

+ 数码管流水灯实现方式

  数码管流水灯采用74HC595移位寄存器和74HC138译码器实现。74HC595是8位串行输入并行输出芯片，通过SI、SCK、RCK三根控制线将段码数据串行发送后并行输出到数码管的8个段。本实验定义了6个段码，每个段码只点亮一个段（a~f段），通过segment_pos变量控制当前显示的段。74HC138译码器通过3根控制线（A、B、C）可以选择8个数码管中的一个，本实验固定选择第0位数码管。每次中断更新时segment_pos递增并循环，从而实现单个段在数码管上依次点亮的流水效果。

+ LED流水灯实现方式

  LED流水灯采用双模式设计，8个LED直接连接到GPIOF的PF0~PF7引脚，高电平点亮、低电平熄灭。模式0为点亮模式，从LED1开始每次中断点亮一个LED，使用位移操作选择对应引脚，当8个LED全部点亮后切换到模式1。模式1为熄灭模式，同样从LED1开始依次熄灭，当全部熄灭后切换回模式0。通过led_mode和led_pos两个状态变量控制，形成LED依次点亮再依次熄灭的循环流水效果。

+ 交通灯流水效果

  交通灯使用简单的二状态机实现两组灯的交替闪烁。第一组交通灯（红1、黄1、绿1）连接PF8\~PF10，第二组（红2、黄2、绿2）连接PF11~PF13。状态0时第一组全亮、第二组全灭，状态1时第一组全灭、第二组全亮。每次中断更新时状态切换一次，两组灯互补控制，形成交替闪烁的流水效果。

+ 频率调节机制

  频率调节采用软件分频方式实现。定时器TIM3以固定的10Hz频率（每100ms）产生中断，通过speed_divider变量控制实际更新频率。中断中使用计数器累加，当计数器达到speed_divider时才执行任务更新并清零计数器，因此实际更新频率等于10Hz除以speed_divider。按钮1减小speed_divider提高频率（最小值2对应5Hz），按钮2增大speed_divider降低频率（最大值50对应0.2Hz），从而实现灵活的速度调节，范围从每200ms更新一次到每5秒更新一次。

== 实验总结

通过这次实验，我掌握了STM32定时器中断的配置方法，学会了如何计算预分频器和自动重装载值来获得精确的中断频率。状态机的设计模式让程序逻辑清晰，每个任务用状态变量描述流程，便于调试和扩展。

更重要的是，我建立了中断驱动编程的思维模式。主循环为空，所有功能由中断触发，这与传统轮询方式不同，大大提高了系统效率。三个任务通过时间片轮询实现并发，各自独立互不干扰，这种多任务设计思想为今后学习嵌入式开发打下了基础。

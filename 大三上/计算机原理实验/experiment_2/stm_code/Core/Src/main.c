/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2025 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <string.h>
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
TIM_HandleTypeDef htim4;

/* USER CODE BEGIN PV */
SystemState_t sys_state = {0};
volatile uint8_t display_buffer[8] = {0};
volatile uint8_t current_digit = 0;

// 数码管段码表 (共阴数码管: 0-9, A-F)
const uint8_t DigitCode[16] = {
    0x3F, // 0
    0x06, // 1
    0x5B, // 2
    0x4F, // 3
    0x66, // 4
    0x6D, // 5
    0x7D, // 6
    0x07, // 7
    0x7F, // 8
    0x6F, // 9
    0x77, // A
    0x7C, // B
    0x39, // C
    0x5E, // D
    0x79, // E
    0x71  // F
};
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_TIM4_Init(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

// 74HC595发送一个字节
void HC595_SendByte(uint8_t data) {
    HAL_GPIO_WritePin(HC595_RCK_PORT, HC595_RCK_PIN, GPIO_PIN_RESET);
    
    for (int i = 7; i >= 0; i--) {
        HAL_GPIO_WritePin(HC595_SCK_PORT, HC595_SCK_PIN, GPIO_PIN_RESET);
        
        if (data & (1 << i)) {
            HAL_GPIO_WritePin(HC595_SI_PORT, HC595_SI_PIN, GPIO_PIN_SET);
        } else {
            HAL_GPIO_WritePin(HC595_SI_PORT, HC595_SI_PIN, GPIO_PIN_RESET);
        }
        
        HAL_GPIO_WritePin(HC595_SCK_PORT, HC595_SCK_PIN, GPIO_PIN_SET);
    }
    
    HAL_GPIO_WritePin(HC595_RCK_PORT, HC595_RCK_PIN, GPIO_PIN_SET);
}

// 74HC138选择数码管位
void HC138_Select(uint8_t digit) {
    HAL_GPIO_WritePin(HC138_A_PORT, HC138_A_PIN, (digit & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
    HAL_GPIO_WritePin(HC138_B_PORT, HC138_B_PIN, (digit & 0x02) ? GPIO_PIN_SET : GPIO_PIN_RESET);
    HAL_GPIO_WritePin(HC138_C_PORT, HC138_C_PIN, (digit & 0x04) ? GPIO_PIN_SET : GPIO_PIN_RESET);
}

// 显示单个数码管
void Display_Digit(uint8_t digit, uint8_t value) {
    HC138_Select(digit);
    HC595_SendByte(value);
}

// 更新数码管显示 (在定时器中断中调用)
void Update_Display(void) {
    // 清除当前显示
    HC595_SendByte(0x00);
    
    // 选择下一位
    current_digit = (current_digit + 1) % 8;
    
    // 显示内容
    HC138_Select(current_digit);
    HC595_SendByte(display_buffer[current_digit]);
}

// 读取拨码开关状态
void Read_Switches(void) {
    uint8_t sw_value = (GPIOC->IDR & 0xFF); // PC0-PC7
    
    sys_state.write_mode = (sw_value & 0x01) ? 1 : 0;        // SW0
    sys_state.ram_select = (sw_value & 0x02) ? 1 : 0;        // SW1
    sys_state.data_to_write = (sw_value >> 2) & 0x03;        // SW2,SW3
    sys_state.addr = (sw_value >> 4) & 0x03;                 // SW4,SW5
}

// 更新LED显示
void Update_LEDs(void) {
    uint8_t led_state = 0;
    
    // LED0: 始终亮表示系统运行
    led_state |= 0x01;
    
    // LED1: 写入模式时亮
    if (sys_state.write_mode) {
        led_state |= 0x02;
    }
    
    // LED2: 选择RAM0时亮
    if (!sys_state.ram_select) {
        led_state |= 0x04;
    }
    
    // LED3: 选择RAM1时亮
    if (sys_state.ram_select) {
        led_state |= 0x08;
    }
    
    // LED4,LED5: 显示地址
    if (sys_state.addr & 0x01) {
        led_state |= 0x10;
    }
    if (sys_state.addr & 0x02) {
        led_state |= 0x20;
    }
    
    // 写入LED端口
    GPIOB->ODR = (GPIOB->ODR & 0xFF00) | led_state;
}

// RAM初始化
void RAM_Init(void) {
    // 设置初始状态
    HAL_GPIO_WritePin(RAM_CLKA_PORT, RAM_CLKA_PIN, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(RAM_CLKB_PORT, RAM_CLKB_PIN, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(RAM_WEA_PORT, RAM_WEA_PIN, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(RAM_WEB_PORT, RAM_WEB_PIN, GPIO_PIN_RESET);
    
    // 使能RAM芯片
    HAL_GPIO_WritePin(RAM_ENA_PORT, RAM_ENA_PIN, GPIO_PIN_SET);
    HAL_GPIO_WritePin(RAM_ENB_PORT, RAM_ENB_PIN, GPIO_PIN_SET);
}

// 向RAM写入数据
void RAM_Write(uint8_t ram_sel, uint8_t addr, uint8_t data) {
    if (ram_sel == 0) {
        // 写入RAM0 (使用端口A)
        // 1. 设置地址
        HAL_GPIO_WritePin(RAM_ADDRA_PORT, RAM_ADDRA_PIN, (addr & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
        for(volatile int i=0; i<100; i++); // 地址稳定延时
        
        // 2. 设置数据（在时钟上升沿之前）
        HAL_GPIO_WritePin(RAM_DIA0_PORT, RAM_DIA0_PIN, (data & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
        HAL_GPIO_WritePin(RAM_DIA1_PORT, RAM_DIA1_PIN, (data & 0x02) ? GPIO_PIN_SET : GPIO_PIN_RESET);
        for(volatile int i=0; i<100; i++); // 数据稳定延时
        
        // 3. 拉高写使能
        HAL_GPIO_WritePin(RAM_WEA_PORT, RAM_WEA_PIN, GPIO_PIN_SET);
        for(volatile int i=0; i<100; i++); // WE稳定延时
        
        // 4. 时钟上升沿写入
        HAL_GPIO_WritePin(RAM_CLKA_PORT, RAM_CLKA_PIN, GPIO_PIN_RESET);
        for(volatile int i=0; i<100; i++); // 时钟低电平稳定
        HAL_GPIO_WritePin(RAM_CLKA_PORT, RAM_CLKA_PIN, GPIO_PIN_SET);
        for(volatile int i=0; i<200; i++); // 时钟高电平稳定，完成写入
        
        // 5. 复位所有控制信号（重要：防止代码变成一次性的）
        HAL_GPIO_WritePin(RAM_CLKA_PORT, RAM_CLKA_PIN, GPIO_PIN_RESET);
        HAL_GPIO_WritePin(RAM_WEA_PORT, RAM_WEA_PIN, GPIO_PIN_RESET);
        HAL_GPIO_WritePin(RAM_DIA0_PORT, RAM_DIA0_PIN, GPIO_PIN_RESET);
        HAL_GPIO_WritePin(RAM_DIA1_PORT, RAM_DIA1_PIN, GPIO_PIN_RESET);
        for(volatile int i=0; i<100; i++); // 确保信号复位稳定
    } else {
        // 写入RAM1 (使用端口B)
        // 1. 设置地址
        HAL_GPIO_WritePin(RAM_ADDRB_PORT, RAM_ADDRB_PIN, (addr & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
        for(volatile int i=0; i<100; i++); // 地址稳定延时
        
        // 2. 设置数据（在时钟上升沿之前）
        HAL_GPIO_WritePin(RAM_DIB0_PORT, RAM_DIB0_PIN, (data & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
        HAL_GPIO_WritePin(RAM_DIB1_PORT, RAM_DIB1_PIN, (data & 0x02) ? GPIO_PIN_SET : GPIO_PIN_RESET);
        for(volatile int i=0; i<100; i++); // 数据稳定延时
        
        // 3. 拉高写使能
        HAL_GPIO_WritePin(RAM_WEB_PORT, RAM_WEB_PIN, GPIO_PIN_SET);
        for(volatile int i=0; i<100; i++); // WE稳定延时
        
        // 4. 时钟上升沿写入
        HAL_GPIO_WritePin(RAM_CLKB_PORT, RAM_CLKB_PIN, GPIO_PIN_RESET);
        for(volatile int i=0; i<100; i++); // 时钟低电平稳定
        HAL_GPIO_WritePin(RAM_CLKB_PORT, RAM_CLKB_PIN, GPIO_PIN_SET);
        for(volatile int i=0; i<200; i++); // 时钟高电平稳定，完成写入
        
        // 5. 复位所有控制信号（重要：防止代码变成一次性的）
        HAL_GPIO_WritePin(RAM_CLKB_PORT, RAM_CLKB_PIN, GPIO_PIN_RESET);
        HAL_GPIO_WritePin(RAM_WEB_PORT, RAM_WEB_PIN, GPIO_PIN_RESET);
        HAL_GPIO_WritePin(RAM_DIB0_PORT, RAM_DIB0_PIN, GPIO_PIN_RESET);
        HAL_GPIO_WritePin(RAM_DIB1_PORT, RAM_DIB1_PIN, GPIO_PIN_RESET);
        for(volatile int i=0; i<100; i++); // 确保信号复位稳定
    }
}

// 从RAM读取数据
void RAM_Read(uint8_t ram_sel, uint8_t addr) {
    if (ram_sel == 0) {
        // 读取RAM0 (使用端口A)
        // 1. 使能RAM0
        HAL_GPIO_WritePin(RAM_ENA_PORT, RAM_ENA_PIN, GPIO_PIN_SET);
        
        // 2. 确保写使能为低（读模式）
        HAL_GPIO_WritePin(RAM_WEA_PORT, RAM_WEA_PIN, GPIO_PIN_RESET);
        
        // 3. 设置地址
        HAL_GPIO_WritePin(RAM_ADDRA_PORT, RAM_ADDRA_PIN, (addr & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
        for(volatile int i=0; i<100; i++); // 地址稳定延时
        
        // 4. 时钟上升沿（触发读取）
        HAL_GPIO_WritePin(RAM_CLKA_PORT, RAM_CLKA_PIN, GPIO_PIN_RESET);
        for(volatile int i=0; i<100; i++);
        HAL_GPIO_WritePin(RAM_CLKA_PORT, RAM_CLKA_PIN, GPIO_PIN_SET);
        for(volatile int i=0; i<100; i++); // 等待数据输出稳定
        
        // 5. 读取输出数据
        uint8_t data = 0;
        if (HAL_GPIO_ReadPin(RAM_DOA0_PORT, RAM_DOA0_PIN)) data |= 0x01;
        if (HAL_GPIO_ReadPin(RAM_DOA1_PORT, RAM_DOA1_PIN)) data |= 0x02;
        sys_state.ram0_data = data;
        
        // 6. 时钟回到低电平
        HAL_GPIO_WritePin(RAM_CLKA_PORT, RAM_CLKA_PIN, GPIO_PIN_RESET);
    } else {
        // 读取RAM1 (使用端口B)
        // 1. 使能RAM1
        HAL_GPIO_WritePin(RAM_ENB_PORT, RAM_ENB_PIN, GPIO_PIN_SET);
        
        // 2. 确保写使能为低（读模式）
        HAL_GPIO_WritePin(RAM_WEB_PORT, RAM_WEB_PIN, GPIO_PIN_RESET);
        
        // 3. 设置地址
        HAL_GPIO_WritePin(RAM_ADDRB_PORT, RAM_ADDRB_PIN, (addr & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
        for(volatile int i=0; i<100; i++); // 地址稳定延时
        
        // 4. 时钟上升沿（触发读取）
        HAL_GPIO_WritePin(RAM_CLKB_PORT, RAM_CLKB_PIN, GPIO_PIN_RESET);
        for(volatile int i=0; i<100; i++);
        HAL_GPIO_WritePin(RAM_CLKB_PORT, RAM_CLKB_PIN, GPIO_PIN_SET);
        for(volatile int i=0; i<100; i++); // 等待数据输出稳定
        
        // 5. 读取输出数据
        uint8_t data = 0;
        if (HAL_GPIO_ReadPin(RAM_DOB0_PORT, RAM_DOB0_PIN)) data |= 0x01;
        if (HAL_GPIO_ReadPin(RAM_DOB1_PORT, RAM_DOB1_PIN)) data |= 0x02;
        sys_state.ram1_data = data;
        
        // 6. 时钟回到低电平
        HAL_GPIO_WritePin(RAM_CLKB_PORT, RAM_CLKB_PIN, GPIO_PIN_RESET);
    }
}

// 更新数码管显示缓冲区
void Update_Display_Buffer(void) {
    // 数码管从右到左: 位1(buffer[0])到位8(buffer[7])
    // 位1-4: 展示RAM数据 (格式: RAM0.RAM1，即 bit1 bit0 . bit1 bit0)
    // 位7-8: 展示待写入数据 (格式: bit1 bit0)
    
    // 位1: RAM1 bit0
    display_buffer[0] = (sys_state.ram1_data & 0x01) ? DigitCode[1] : DigitCode[0];
    
    // 位2: RAM1 bit1
    display_buffer[1] = (sys_state.ram1_data & 0x02) ? DigitCode[1] : DigitCode[0];
    
    // 位3: RAM0 bit0 + 小数点
    display_buffer[2] = ((sys_state.ram0_data & 0x01) ? DigitCode[1] : DigitCode[0]) | 0x80;
    
    // 位4: RAM0 bit1
    display_buffer[3] = (sys_state.ram0_data & 0x02) ? DigitCode[1] : DigitCode[0];
    
    // 位5-6: 保留，清零
    display_buffer[4] = 0x00;
    display_buffer[5] = 0x00;
    
    // 位7: 待写入数据 bit0
    display_buffer[6] = (sys_state.data_to_write & 0x01) ? DigitCode[1] : DigitCode[0];
    
    // 位8: 待写入数据 bit1
    display_buffer[7] = (sys_state.data_to_write & 0x02) ? DigitCode[1] : DigitCode[0];
}

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_TIM4_Init();
  /* USER CODE BEGIN 2 */
  // 初始化RAM
  RAM_Init();
  
  // 启动定时器中断 (用于数码管扫描)
  HAL_TIM_Base_Start_IT(&htim4);
  
  // 短延时，等待系统稳定
  HAL_Delay(10);
  
  // 初始读取数据
  RAM_Read(0, sys_state.addr);
  RAM_Read(1, sys_state.addr);
  
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
    // 读取拨码开关状态
    Read_Switches();
    
    // 更新LED显示
    Update_LEDs();
    
    // 从RAM读取数据
    RAM_Read(0, sys_state.addr);
    RAM_Read(1, sys_state.addr);
    
    // 更新数码管显示缓冲
    Update_Display_Buffer();
    
    HAL_Delay(50); // 主循环延时
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_NONE;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_HSI;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief TIM4 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM4_Init(void)
{

  /* USER CODE BEGIN TIM4_Init 0 */

  /* USER CODE END TIM4_Init 0 */

  TIM_ClockConfigTypeDef sClockSourceConfig = {0};
  TIM_MasterConfigTypeDef sMasterConfig = {0};

  /* USER CODE BEGIN TIM4_Init 1 */

  /* USER CODE END TIM4_Init 1 */
  htim4.Instance = TIM4;
  htim4.Init.Prescaler = 81;  // 82MHz / 82 = 1MHz
  htim4.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim4.Init.Period = 999;    // 1MHz / 1000 = 1kHz (1ms中断)
  htim4.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim4.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_ENABLE;
  if (HAL_TIM_Base_Init(&htim4) != HAL_OK)
  {
    Error_Handler();
  }
  sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
  if (HAL_TIM_ConfigClockSource(&htim4, &sClockSourceConfig) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim4, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM4_Init 2 */

  /* USER CODE END TIM4_Init 2 */

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};
  /* USER CODE BEGIN MX_GPIO_Init_1 */

  /* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOF_CLK_ENABLE();
  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOF, GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_4|GPIO_PIN_5
                          |GPIO_PIN_6|GPIO_PIN_7|GPIO_PIN_8|GPIO_PIN_9
                          |GPIO_PIN_12|GPIO_PIN_13|GPIO_PIN_14|GPIO_PIN_15, GPIO_PIN_RESET);

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_2|GPIO_PIN_3
                          |GPIO_PIN_4|GPIO_PIN_5, GPIO_PIN_RESET);

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOB, GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_2|GPIO_PIN_3
                          |GPIO_PIN_4|GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7, GPIO_PIN_RESET);

  /*Configure GPIO pins : PF0 PF1 PF4 PF5
                           PF6 PF7 PF8 PF9
                           PF12 PF13 PF14 PF15 */
  GPIO_InitStruct.Pin = GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_4|GPIO_PIN_5
                          |GPIO_PIN_6|GPIO_PIN_7|GPIO_PIN_8|GPIO_PIN_9
                          |GPIO_PIN_12|GPIO_PIN_13|GPIO_PIN_14|GPIO_PIN_15;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOF, &GPIO_InitStruct);

  /*Configure GPIO pins : PF2 PF3 PF10 PF11 */
  GPIO_InitStruct.Pin = GPIO_PIN_2|GPIO_PIN_3|GPIO_PIN_10|GPIO_PIN_11;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(GPIOF, &GPIO_InitStruct);

  /*Configure GPIO pins : PC0 PC1 PC2 PC3
                           PC4 PC5 PC6 PC7 */
  GPIO_InitStruct.Pin = GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_2|GPIO_PIN_3
                          |GPIO_PIN_4|GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);

  /*Configure GPIO pins : PA0 PA1 PA2 PA3
                           PA4 PA5 */
  GPIO_InitStruct.Pin = GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_2|GPIO_PIN_3
                          |GPIO_PIN_4|GPIO_PIN_5;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  /*Configure GPIO pins : PB0 PB1 PB2 PB3
                           PB4 PB5 PB6 PB7 */
  GPIO_InitStruct.Pin = GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_2|GPIO_PIN_3
                          |GPIO_PIN_4|GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

  /*Configure GPIO pins : PC9 PC12 */
  GPIO_InitStruct.Pin = GPIO_PIN_9|GPIO_PIN_12;
  GPIO_InitStruct.Mode = GPIO_MODE_IT_RISING;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);

  /* EXTI interrupt init*/
  HAL_NVIC_SetPriority(EXTI9_5_IRQn, 0, 0);
  HAL_NVIC_EnableIRQ(EXTI9_5_IRQn);

  HAL_NVIC_SetPriority(EXTI15_10_IRQn, 0, 0);
  HAL_NVIC_EnableIRQ(EXTI15_10_IRQn);

  /* USER CODE BEGIN MX_GPIO_Init_2 */

  /* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */

// GPIO外部中断回调函数
void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin) {
    static uint32_t last_btn0_time = 0;
    static uint32_t last_btn1_time = 0;
    uint32_t current_time = HAL_GetTick();
    
    if (GPIO_Pin == GPIO_PIN_9) {
        // 按钮0 (PC9): 写入数据到选定的RAM
        // 软件消抖：50ms内的重复触发忽略
        if (current_time - last_btn0_time > 50) {
            if (sys_state.write_mode) {
                RAM_Write(sys_state.ram_select, sys_state.addr, sys_state.data_to_write);
                // 写入后立即读取，更新显示
                RAM_Read(sys_state.ram_select, sys_state.addr);
            }
            last_btn0_time = current_time;
        }
    } 
    else if (GPIO_Pin == GPIO_PIN_12) {
        // 按钮1 (PC12): 异或操作
        // 软件消抖：50ms内的重复触发忽略
        if (current_time - last_btn1_time > 50) {
            // 从两个RAM读取数据
            RAM_Read(0, sys_state.addr);
            RAM_Read(1, sys_state.addr);
            
            // 异或操作
            uint8_t xor_result = sys_state.ram0_data ^ sys_state.ram1_data;
            
            // 写回到选定的RAM
            RAM_Write(sys_state.ram_select, sys_state.addr, xor_result);
            
            // 写入后立即读取，更新显示
            RAM_Read(0, sys_state.addr);
            RAM_Read(1, sys_state.addr);
            
            last_btn1_time = current_time;
        }
    }
}

// 定时器中断回调函数 (用于数码管扫描)
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim) {
    if (htim->Instance == TIM4) {
        Update_Display();
    }
}

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}
#ifdef USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */

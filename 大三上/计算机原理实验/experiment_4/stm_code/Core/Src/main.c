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
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <stdarg.h>
#include "lcd.h"
#include "seg7.h"
#include "fpga_comm.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */
typedef enum {
    SYS_STATE_IDLE = 0,
    SYS_STATE_WAIT_HANDSHAKE,
    SYS_STATE_RECEIVING,
    SYS_STATE_DISPLAY_READY,
    SYS_STATE_FPGA_PROCESSING,
    SYS_STATE_RESULT_READY
} System_State_t;
/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
#define DIGIT_SIZE 784  // 28x28 pixels
#define PACKED_SIZE 98  // 784 pixels / 4 pixels per nibble / 2 nibbles per byte = 98 bytes
#define HEX_STRING_SIZE (PACKED_SIZE * 2)  // 196 hex characters (2 chars per byte)
#define UART_BUFFER_SIZE 1024
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */
#ifdef __GNUC__
#define PUTCHAR_PROTOTYPE int __io_putchar(int ch)
#else
#define PUTCHAR_PROTOTYPE int fputc(int ch, FILE *f)
#endif
/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
TIM_HandleTypeDef htim4;

UART_HandleTypeDef huart1;

SRAM_HandleTypeDef hsram1;

/* USER CODE BEGIN PV */
static uint8_t digit_data[DIGIT_SIZE];
static uint8_t packed_buffer[PACKED_SIZE];
static System_State_t system_state = SYS_STATE_IDLE;
static bool button_pressed = false;
static uint8_t uart_rx_byte;
static char hex_string_buffer[HEX_STRING_SIZE + 10];  // +10 for \r\n and safety
static uint16_t hex_string_index = 0;
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_FSMC_Init(void);
static void MX_TIM4_Init(void);
static void MX_USART1_UART_Init(void);
/* USER CODE BEGIN PFP */
void UART_Printf(const char *format, ...);
void UnpackDigitData(const uint8_t *packed_data, uint8_t *digit_data);
void ProcessReceivedData(void);
void StartFPGAProcessing(void);
uint8_t HexCharToValue(char c);
void ParseHexString(const char *hex_str, uint8_t *output, uint16_t output_size);
void ProcessUARTByte(uint8_t byte);
/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

/**
  * @brief  Retargets the C library printf function to the USART.
  */
PUTCHAR_PROTOTYPE
{
    HAL_UART_Transmit(&huart1, (uint8_t *)&ch, 1, 0xFFFF);
    return ch;
}

/**
  * @brief  UART printf wrapper
  */
void UART_Printf(const char *format, ...)
{
    char buffer[256];
    va_list args;
    va_start(args, format);
    vsnprintf(buffer, sizeof(buffer), format, args);
    va_end(args);
    HAL_UART_Transmit(&huart1, (uint8_t *)buffer, strlen(buffer), 1000);
}

/**
  * @brief  Unpack 4-bits-per-nibble packed data to 1-byte-per-pixel format
  * @param  packed_data: Pointer to packed data (98 bytes)
  * @param  digit_data: Pointer to unpacked data buffer (784 bytes)
  */
void UnpackDigitData(const uint8_t *packed_data, uint8_t *digit_data)
{
    // Unpack 98 bytes to 784 bytes
    // Each byte contains 2 nibbles, each nibble contains 4 pixels
    for(uint16_t i = 0; i < PACKED_SIZE; i++)
    {
        uint8_t byte_val = packed_data[i];
        
        // Extract high nibble (4 pixels)
        uint8_t high_nibble = (byte_val >> 4) & 0x0F;
        for(uint8_t j = 0; j < 4; j++)
        {
            uint16_t pixel_idx = i * 8 + j;
            if(pixel_idx < DIGIT_SIZE)
            {
                digit_data[pixel_idx] = (high_nibble >> (3 - j)) & 0x01;
            }
        }
        
        // Extract low nibble (4 pixels)
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

/**
  * @brief  Convert hex character to value
  */
uint8_t HexCharToValue(char c)
{
    if(c >= '0' && c <= '9')
        return c - '0';
    else if(c >= 'A' && c <= 'F')
        return c - 'A' + 10;
    else if(c >= 'a' && c <= 'f')
        return c - 'a' + 10;
    return 0;
}

/**
  * @brief  Parse hex string to binary data
  */
void ParseHexString(const char *hex_str, uint8_t *output, uint16_t output_size)
{
    for(uint16_t i = 0; i < output_size && i * 2 + 1 < strlen(hex_str); i++)
    {
        uint8_t high = HexCharToValue(hex_str[i * 2]);
        uint8_t low = HexCharToValue(hex_str[i * 2 + 1]);
        output[i] = (high << 4) | low;
    }
}

/**
  * @brief  Process UART byte by byte
  */
void ProcessUARTByte(uint8_t byte)
{
    switch(system_state)
    {
        case SYS_STATE_IDLE:
            // Looking for handshake 'Q'
            if(byte == 'Q')
            {
                UART_Printf("[HANDSHAKE] Received 'Q'\r\n");
                UART_Printf("A\r\n");  // Send acknowledgment
                system_state = SYS_STATE_WAIT_HANDSHAKE;
                hex_string_index = 0;
                memset(hex_string_buffer, 0, sizeof(hex_string_buffer));
            }
            // Ignore other bytes in IDLE state
            break;
            
        case SYS_STATE_WAIT_HANDSHAKE:
            // Waiting for hex string data terminated by \r\n
            if(byte == '\r' || byte == '\n')
            {
                // Check if we have enough data (only process when we have data)
                if(hex_string_index > 0)
                {
                    if(hex_string_index >= HEX_STRING_SIZE)
                    {
                        // Null-terminate the string
                        hex_string_buffer[hex_string_index] = '\0';
                        
                        // Parse hex string to packed binary data
                        UART_Printf("[DATA] Received %d hex chars\r\n", hex_string_index);
                        ParseHexString(hex_string_buffer, packed_buffer, PACKED_SIZE);
                        
                        // Unpack data from 4-bits-per-nibble to 1-byte-per-pixel
                        UART_Printf("[DATA] Unpacking data...\r\n");
                        UnpackDigitData(packed_buffer, digit_data);
                        UART_Printf("[DATA] Unpacked to %d pixels\r\n", DIGIT_SIZE);
                        
                        // Display on LCD
                        UART_Printf("[LCD] Displaying digit on LCD...\r\n");
                        LCD_DisplayDigit(digit_data);
                        
                        // Update system state
                        system_state = SYS_STATE_DISPLAY_READY;
                        
                        UART_Printf("[INFO] Display complete. Press button to send to FPGA\r\n");
                    }
                    else
                    {
                        UART_Printf("[ERROR] Incomplete hex string: %d chars (expected %d)\r\n", 
                                    hex_string_index, HEX_STRING_SIZE);
                        system_state = SYS_STATE_IDLE;
                    }
                    hex_string_index = 0;
                }
                // Ignore empty \r\n (from handshake)
            }
            else if(hex_string_index < sizeof(hex_string_buffer) - 1)
            {
                // Store valid hex characters only
                if((byte >= '0' && byte <= '9') || 
                   (byte >= 'A' && byte <= 'F') || 
                   (byte >= 'a' && byte <= 'f'))
                {
                    hex_string_buffer[hex_string_index++] = (char)byte;
                }
                else
                {
                    // Ignore invalid characters (space, etc.)
                }
            }
            break;
            
        case SYS_STATE_DISPLAY_READY:
        case SYS_STATE_FPGA_PROCESSING:
        case SYS_STATE_RESULT_READY:
            // Ignore UART data while processing or displaying results
            break;
            
        default:
            // Unknown state - reset to IDLE
            system_state = SYS_STATE_IDLE;
            break;
    }
}

/**
  * @brief  Process received UART data (legacy function - now handled in ProcessUARTByte)
  */
void ProcessReceivedData(void)
{
    // This function is now deprecated - processing happens in ProcessUARTByte
}

/**
  * @brief  Start FPGA processing
  */
void StartFPGAProcessing(void)
{
    if(system_state == SYS_STATE_DISPLAY_READY)
    {
        UART_Printf("[INFO] Button pressed! Starting FPGA processing...\r\n");
        
        // Print FPGA status before starting
        FPGA_PrintDetailedStatus();
        
        // Set FPGA data
        FPGA_SetData(digit_data);
        
        // Start sending to FPGA
        FPGA_StartSend(digit_data, DIGIT_SIZE);
        
        // Update state
        system_state = SYS_STATE_FPGA_PROCESSING;
        
        UART_Printf("[INFO] Sending data to FPGA...\r\n");
        UART_Printf("[INFO] Data transmission started (784 bits at 500Hz = ~1.6 seconds)\r\n");
    }
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
  MX_FSMC_Init();
  MX_TIM4_Init();
  MX_USART1_UART_Init();
  /* USER CODE BEGIN 2 */
  
  // Initialize modules
  UART_Printf("\r\n=== Handwriting Recognition System ===\r\n");
  UART_Printf("[INFO] Initializing...\r\n");
  
  // Test backlight GPIO directly first (ACTIVE-LOW for PNP/P-MOS)
  UART_Printf("[INFO] Testing backlight GPIO (PB0)...\r\n");
  HAL_GPIO_WritePin(GPIOB, GPIO_PIN_0, GPIO_PIN_RESET);
  UART_Printf("[INFO] Backlight ON (PB0=LOW, active-low)\r\n");
  HAL_Delay(500);
  
  // Initialize LCD
  UART_Printf("[INFO] Initializing LCD controller...\r\n");
  LCD_Init();
  UART_Printf("[INFO] LCD controller initialized\r\n");
  
  UART_Printf("[INFO] Drawing test pattern...\r\n");
  LCD_DisplayTestPattern();  // Show 28x28 checkerboard test pattern
  UART_Printf("[INFO] LCD initialized with test pattern\r\n");
  UART_Printf("[INFO] If screen is black, check:\r\n");
  UART_Printf("[INFO]   - PB0 should be LOW (0V) for backlight ON\r\n");
  UART_Printf("[INFO]   - LCD power supply (VDD and LED+)\r\n");
  UART_Printf("[INFO]   - FSMC connections\r\n");
  
  // Initialize 7-segment display
  SEG7_Init();
  SEG7_AllOn();  // Display all 8s on startup
  UART_Printf("[INFO] 7-segment display initialized (all on)\r\n");
  
  // Initialize FPGA interface
  FPGA_Init();
  UART_Printf("[INFO] FPGA interface initialized\r\n");
  
  // Configure TIM4 for 500Hz (period = 1/500 = 2ms)
  // TIM4 clock = 84MHz (APB1 * 2)
  // Prescaler = 84-1 (1MHz)
  // Period = 2000-1 (500Hz)
  htim4.Init.Prescaler = 84 - 1;
  htim4.Init.Period = 2000 - 1;
  if (HAL_TIM_Base_Init(&htim4) != HAL_OK)
  {
    Error_Handler();
  }
  
  // Start TIM4 interrupt
  HAL_TIM_Base_Start_IT(&htim4);
  UART_Printf("[INFO] Timer started at 500Hz\r\n");
  
  // Start UART receive interrupt
  if(HAL_UART_Receive_IT(&huart1, &uart_rx_byte, 1) == HAL_OK)
  {
      UART_Printf("[INFO] UART interrupt started successfully\r\n");
  }
  else
  {
      UART_Printf("[ERROR] Failed to start UART interrupt!\r\n");
  }
  
  UART_Printf("\r\n=== System Ready ===\r\n");
  UART_Printf("[INFO] UART: 115200 baud, 8N1\r\n");
  UART_Printf("[INFO] Protocol:\r\n");
  UART_Printf("  1. Send 'Q\\r\\n' to initiate handshake\r\n");
  UART_Printf("  2. Wait for 'A\\r\\n' acknowledgment\r\n");
  UART_Printf("  3. Send %d hex chars (packed data) + \\r\\n\r\n", HEX_STRING_SIZE);
  UART_Printf("[INFO] Waiting for data...\r\n\r\n");
  
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  uint32_t last_fpga_status_print = 0;
  uint32_t fpga_send_start_time = 0;
  bool fpga_sending_logged = false;
  
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
    
    // Refresh 7-segment display
    SEG7_Refresh();
    HAL_Delay(1);
    
    // Check FPGA state
    if(system_state == SYS_STATE_FPGA_PROCESSING)
    {
        FPGA_State_t fpga_state = FPGA_GetState();
        
        // Log when sending starts
        if(fpga_state == FPGA_STATE_SENDING && !fpga_sending_logged)
        {
            fpga_send_start_time = HAL_GetTick();
            fpga_sending_logged = true;
            UART_Printf("\r\n[FPGA] Starting data transmission...\r\n");
            FPGA_PrintIOStatus();
        }
        // Log when sending completes and computing starts
        else if(fpga_state == FPGA_STATE_COMPUTING && fpga_sending_logged)
        {
            uint32_t send_duration = HAL_GetTick() - fpga_send_start_time;
            UART_Printf("\r\n[FPGA] Data transmission complete (took %lu ms)\r\n", send_duration);
            UART_Printf("[FPGA] FPGA now computing...\r\n");
            FPGA_PrintDetailedStatus();
            fpga_sending_logged = false;
        }
        // Print status every 1 second during computing
        else if(fpga_state == FPGA_STATE_COMPUTING && (HAL_GetTick() - last_fpga_status_print > 1000))
        {
            last_fpga_status_print = HAL_GetTick();
            UART_Printf("[FPGA] Computing... ");
            FPGA_PrintIOStatus();
        }
        
        if(fpga_state == FPGA_STATE_COMPUTING && !FPGA_IsBusy())
        {
            // FPGA finished computing, check for result
            if(FPGA_IsResultValid())
            {
                uint8_t result = FPGA_ReadResult();
                
                UART_Printf("\r\n=================================\r\n");
                UART_Printf("[RESULT] Recognized digit: %d\r\n", result);
                UART_Printf("=================================\r\n\r\n");
                
                // Print final FPGA status
                FPGA_PrintDetailedStatus();
                
                // Display result on first digit of 7-segment
                SEG7_Clear();
                SEG7_SetBuffer(0, result);
                
                // Update LCD
                char result_str[32];
                snprintf(result_str, sizeof(result_str), "Result: %d", result);
                LCD_DrawString(10, 50, result_str, LCD_COLOR_GREEN, LCD_COLOR_WHITE);
                
                // Send OK to PC
                UART_Printf("OK\r\n");
                
                // Reset button flag
                button_pressed = false;
                
                // Update state - go back to IDLE for next input
                system_state = SYS_STATE_IDLE;
                
                UART_Printf("[INFO] Ready for next input\r\n\r\n");
            }
            else
            {
                UART_Printf("[WARNING] FPGA not busy but RESULT_VALID is LOW\r\n");
                FPGA_PrintIOStatus();
            }
        }
    }
    else
    {
        // Reset flag when not processing
        fpga_sending_logged = false;
    }
    
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
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLM = 8;
  RCC_OscInitStruct.PLL.PLLN = 84;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
  RCC_OscInitStruct.PLL.PLLQ = 4;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV2;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
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
  htim4.Init.Prescaler = 0;
  htim4.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim4.Init.Period = 65535;
  htim4.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim4.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
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
  * @brief USART1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART1_UART_Init(void)
{

  /* USER CODE BEGIN USART1_Init 0 */

  /* USER CODE END USART1_Init 0 */

  /* USER CODE BEGIN USART1_Init 1 */

  /* USER CODE END USART1_Init 1 */
  huart1.Instance = USART1;
  huart1.Init.BaudRate = 115200;
  huart1.Init.WordLength = UART_WORDLENGTH_8B;
  huart1.Init.StopBits = UART_STOPBITS_1;
  huart1.Init.Parity = UART_PARITY_NONE;
  huart1.Init.Mode = UART_MODE_TX_RX;
  huart1.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart1.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart1) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART1_Init 2 */

  /* USER CODE END USART1_Init 2 */

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
  __HAL_RCC_GPIOB_CLK_ENABLE();
  __HAL_RCC_GPIOE_CLK_ENABLE();
  __HAL_RCC_GPIOD_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOG_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOF, GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_2|GPIO_PIN_3
                          |GPIO_PIN_4|GPIO_PIN_5, GPIO_PIN_RESET);

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOC, GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_2, GPIO_PIN_RESET);

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOB, GPIO_PIN_0|GPIO_PIN_2, GPIO_PIN_RESET);

  /*Configure GPIO pins : PF0 PF1 PF2 PF3
                           PF4 PF5 */
  GPIO_InitStruct.Pin = GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_2|GPIO_PIN_3
                          |GPIO_PIN_4|GPIO_PIN_5;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOF, &GPIO_InitStruct);

  /*Configure GPIO pins : PC0 PC1 PC2 */
  GPIO_InitStruct.Pin = GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_2;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);

  /*Configure GPIO pins : PC3 PC8 */
  GPIO_InitStruct.Pin = GPIO_PIN_3|GPIO_PIN_8;
  GPIO_InitStruct.Mode = GPIO_MODE_IT_RISING;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);

  /*Configure GPIO pins : PC4 PC5 PC6 PC7 */
  GPIO_InitStruct.Pin = GPIO_PIN_4|GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);

  /*Configure GPIO pins : PB0 PB2 */
  GPIO_InitStruct.Pin = GPIO_PIN_0|GPIO_PIN_2;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

  /*Configure GPIO pin : PA12 */
  GPIO_InitStruct.Pin = GPIO_PIN_12;
  GPIO_InitStruct.Mode = GPIO_MODE_IT_RISING;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  /* EXTI interrupt init*/
  HAL_NVIC_SetPriority(EXTI3_IRQn, 0, 0);
  HAL_NVIC_EnableIRQ(EXTI3_IRQn);

  HAL_NVIC_SetPriority(EXTI9_5_IRQn, 0, 0);
  HAL_NVIC_EnableIRQ(EXTI9_5_IRQn);

  HAL_NVIC_SetPriority(EXTI15_10_IRQn, 0, 0);
  HAL_NVIC_EnableIRQ(EXTI15_10_IRQn);

  /* USER CODE BEGIN MX_GPIO_Init_2 */

  /* USER CODE END MX_GPIO_Init_2 */
}

/* FSMC initialization function */
static void MX_FSMC_Init(void)
{

  /* USER CODE BEGIN FSMC_Init 0 */

  /* USER CODE END FSMC_Init 0 */

  FSMC_NORSRAM_TimingTypeDef Timing = {0};

  /* USER CODE BEGIN FSMC_Init 1 */

  /* USER CODE END FSMC_Init 1 */

  /** Perform the SRAM1 memory initialization sequence
  */
  hsram1.Instance = FSMC_NORSRAM_DEVICE;
  hsram1.Extended = FSMC_NORSRAM_EXTENDED_DEVICE;
  /* hsram1.Init */
  hsram1.Init.NSBank = FSMC_NORSRAM_BANK4;
  hsram1.Init.DataAddressMux = FSMC_DATA_ADDRESS_MUX_DISABLE;
  hsram1.Init.MemoryType = FSMC_MEMORY_TYPE_SRAM;
  hsram1.Init.MemoryDataWidth = FSMC_NORSRAM_MEM_BUS_WIDTH_16;
  hsram1.Init.BurstAccessMode = FSMC_BURST_ACCESS_MODE_DISABLE;
  hsram1.Init.WaitSignalPolarity = FSMC_WAIT_SIGNAL_POLARITY_LOW;
  hsram1.Init.WrapMode = FSMC_WRAP_MODE_DISABLE;
  hsram1.Init.WaitSignalActive = FSMC_WAIT_TIMING_BEFORE_WS;
  hsram1.Init.WriteOperation = FSMC_WRITE_OPERATION_ENABLE;
  hsram1.Init.WaitSignal = FSMC_WAIT_SIGNAL_DISABLE;
  hsram1.Init.ExtendedMode = FSMC_EXTENDED_MODE_DISABLE;
  hsram1.Init.AsynchronousWait = FSMC_ASYNCHRONOUS_WAIT_DISABLE;
  hsram1.Init.WriteBurst = FSMC_WRITE_BURST_DISABLE;
  hsram1.Init.PageSize = FSMC_PAGE_SIZE_NONE;
  /* Timing */
  Timing.AddressSetupTime = 15;
  Timing.AddressHoldTime = 15;
  Timing.DataSetupTime = 255;
  Timing.BusTurnAroundDuration = 15;
  Timing.CLKDivision = 16;
  Timing.DataLatency = 17;
  Timing.AccessMode = FSMC_ACCESS_MODE_A;
  /* ExtTiming */

  if (HAL_SRAM_Init(&hsram1, &Timing, NULL) != HAL_OK)
  {
    Error_Handler( );
  }

  /* USER CODE BEGIN FSMC_Init 2 */

  /* USER CODE END FSMC_Init 2 */
}

/* USER CODE BEGIN 4 */

/**
  * @brief  Timer period elapsed callback
  * @param  htim: TIM handle
  */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
    if(htim->Instance == TIM4)
    {
        // Called at 500Hz - provide clock to FPGA
        FPGA_ClockTick();
    }
}

/**
  * @brief  UART receive complete callback
  * @param  huart: UART handle
  */
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
    if(huart->Instance == USART1)
    {
        // Process received byte according to protocol
        ProcessUARTByte(uart_rx_byte);
        
        // Re-enable UART interrupt for next byte
        HAL_UART_Receive_IT(&huart1, &uart_rx_byte, 1);
    }
}

/**
  * @brief  GPIO external interrupt callback
  * @param  GPIO_Pin: GPIO pin number
  */
void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin)
{
    if(GPIO_Pin == GPIO_PIN_12)  // PA12 - Button (hardware debounced, active high)
    {
        UART_Printf("\r\n[IRQ] Button pressed!\r\n");
        UART_Printf("[IRQ] Current state=%d (DISPLAY_READY=%d), button_pressed=%d\r\n", 
                   system_state, SYS_STATE_DISPLAY_READY, button_pressed);
        
        // Button is hardware debounced and active high
        if(system_state == SYS_STATE_DISPLAY_READY && !button_pressed)
        {
            UART_Printf("[IRQ] Starting FPGA processing...\r\n");
            button_pressed = true;
            StartFPGAProcessing();
        }
        else
        {
            UART_Printf("[IRQ] Ignored - wrong state or already pressed\r\n");
        }
    }
    else if(GPIO_Pin == GPIO_PIN_8)  // PC8 - FPGA BUSY (rising edge)
    {
        UART_Printf("\r\n[IRQ] BUSY=1 detected! Starting data transmission...\r\n");
        
        // Switch to SENDING state to start transmitting data
        extern FPGA_State_t FPGA_GetState(void);
        extern void FPGA_SetState(FPGA_State_t state);
        
        // Get current state from FPGA module
        FPGA_State_t current_state = FPGA_GetState();
        
        if(current_state == FPGA_STATE_IDLE)
        {
            // Start sending data on next clock cycle
            FPGA_SetState(FPGA_STATE_SENDING);
            UART_Printf("[IRQ] State changed to SENDING, data transmission will begin\r\n");
            FPGA_PrintIOStatus();
        }
    }
    else if(GPIO_Pin == GPIO_PIN_3)  // PC3 - FPGA RESULT_VALID (rising edge)
    {
        UART_Printf("\r\n[IRQ] RESULT_VALID=1 detected! Reading result...\r\n");
        
        // Read result from PC4-PC7
        uint32_t port_value = GPIOC->IDR;
        uint8_t result = (port_value >> 4) & 0x0F;
        
        UART_Printf("[IRQ] Result bits from PC4-PC7:\r\n");
        UART_Printf("[IRQ]   PC4 (bit 0): %d\r\n", (port_value >> 4) & 0x01);
        UART_Printf("[IRQ]   PC5 (bit 1): %d\r\n", (port_value >> 5) & 0x01);
        UART_Printf("[IRQ]   PC6 (bit 2): %d\r\n", (port_value >> 6) & 0x01);
        UART_Printf("[IRQ]   PC7 (bit 3): %d\r\n", (port_value >> 7) & 0x01);
        UART_Printf("[IRQ]   Result: 0x%X (decimal: %d)\r\n", result, result);
        
        // Stop clock and read result
        uint8_t fpga_result = FPGA_ReadResult();
        UART_Printf("[IRQ] Clock stopped, final result: %d\r\n", fpga_result);
        
        // Display result on 7-segment display digit 0, clear others
        SEG7_Clear();  // Clear all digits first
        SEG7_WriteDigit(0, fpga_result);  // Display result on first digit
        UART_Printf("[IRQ] Result %d displayed on 7-segment digit 0\r\n", fpga_result);
        
        // Reset system state to IDLE to prepare for next image
        system_state = SYS_STATE_IDLE;
        button_pressed = false;
        UART_Printf("[IRQ] System reset to IDLE state, ready for next image\r\n");
        UART_Printf("=====================================\r\n\r\n");
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

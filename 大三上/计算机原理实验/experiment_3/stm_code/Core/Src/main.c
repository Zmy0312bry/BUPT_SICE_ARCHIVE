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
#include "tim.h"
#include "gpio.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
// Pin definitions for 74HC595
#define SI_PIN GPIO_PIN_0
#define RCK_PIN GPIO_PIN_1
#define SCK_PIN GPIO_PIN_2
#define SI_PORT GPIOC
#define RCK_PORT GPIOC
#define SCK_PORT GPIOC

// Pin definitions for 74HC138
#define A_PIN GPIO_PIN_3
#define B_PIN GPIO_PIN_4
#define C_PIN GPIO_PIN_5
#define ABC_PORT GPIOC

// LED pins (PF0-PF7)
#define LED_PORT GPIOF
#define LED1_PIN GPIO_PIN_0
#define LED2_PIN GPIO_PIN_1
#define LED3_PIN GPIO_PIN_2
#define LED4_PIN GPIO_PIN_3
#define LED5_PIN GPIO_PIN_4
#define LED6_PIN GPIO_PIN_5
#define LED7_PIN GPIO_PIN_6
#define LED8_PIN GPIO_PIN_7

// Traffic light pins
#define R1_PIN GPIO_PIN_8
#define Y1_PIN GPIO_PIN_9
#define G1_PIN GPIO_PIN_10
#define R2_PIN GPIO_PIN_11
#define Y2_PIN GPIO_PIN_12
#define G2_PIN GPIO_PIN_13
#define TRAFFIC_PORT GPIOF
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */
// 7-segment display codes (common cathode)
const uint8_t digit_codes[10] = {
    0x3F, // 0
    0x06, // 1
    0x5B, // 2
    0x4F, // 3
    0x66, // 4
    0x6D, // 5
    0x7D, // 6
    0x07, // 7
    0x7F, // 8
    0x6F  // 9
};

volatile uint8_t current_digit = 0;
volatile uint32_t last_update_time = 0;

// Interrupt flags
volatile uint8_t pb12_interrupt_active = 0;
volatile uint8_t pb9_interrupt_active = 0;
volatile uint32_t interrupt_start_time = 0;

// Variables for saving PB12 state when preempted
volatile uint8_t pb12_was_preempted = 0;
volatile uint32_t pb12_elapsed_before_preempt = 0;
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
/* USER CODE BEGIN PFP */
void HC595_SendByte(uint8_t data);
void HC138_SelectDigit(uint8_t digit);
void Display_Digit(uint8_t digit);
void Traffic_Light_Task(void);
void LED_Sequential_Task(void);
/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
// Send 8-bit data to 74HC595
void HC595_SendByte(uint8_t data) {
    // Pull RCK low to prepare for data transfer
    HAL_GPIO_WritePin(RCK_PORT, RCK_PIN, GPIO_PIN_RESET);
    
    // Send 8 bits, MSB first
    for (int i = 7; i >= 0; i--) {
        // Pull SCK low
        HAL_GPIO_WritePin(SCK_PORT, SCK_PIN, GPIO_PIN_RESET);
        
        // Set SI to current bit value
        if (data & (1 << i)) {
            HAL_GPIO_WritePin(SI_PORT, SI_PIN, GPIO_PIN_SET);
        } else {
            HAL_GPIO_WritePin(SI_PORT, SI_PIN, GPIO_PIN_RESET);
        }
        
        // Pull SCK high to latch the bit
        HAL_GPIO_WritePin(SCK_PORT, SCK_PIN, GPIO_PIN_SET);
    }
    
    // Pull RCK high to transfer data to output
    HAL_GPIO_WritePin(RCK_PORT, RCK_PIN, GPIO_PIN_SET);
}

// Select digit position using 74HC138
void HC138_SelectDigit(uint8_t digit) {
    // Set ABC pins according to digit (0-7)
    HAL_GPIO_WritePin(ABC_PORT, A_PIN, (digit & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
    HAL_GPIO_WritePin(ABC_PORT, B_PIN, (digit & 0x02) ? GPIO_PIN_SET : GPIO_PIN_RESET);
    HAL_GPIO_WritePin(ABC_PORT, C_PIN, (digit & 0x04) ? GPIO_PIN_SET : GPIO_PIN_RESET);
}

// Display a digit on the 7-segment display
void Display_Digit(uint8_t digit) {
    if (digit > 9) digit = 0;
    HC138_SelectDigit(0); // Select first digit position
    HC595_SendByte(digit_codes[digit]);
}

// Traffic light blinking task (for PB12 interrupt)
void Traffic_Light_Task(void) {
    uint32_t elapsed = HAL_GetTick() - interrupt_start_time;
    
    if (elapsed >= 3000) {
        // Turn off all traffic lights
        HAL_GPIO_WritePin(TRAFFIC_PORT, R1_PIN | Y1_PIN | G1_PIN | R2_PIN | Y2_PIN | G2_PIN, GPIO_PIN_RESET);
        pb12_interrupt_active = 0;
        return;
    }
    
    // Blink every 250ms
    uint32_t phase = (elapsed / 250) % 2;
    
    if (phase == 0) {
        // Light up group 1
        HAL_GPIO_WritePin(TRAFFIC_PORT, R1_PIN | Y1_PIN | G1_PIN, GPIO_PIN_SET);
        HAL_GPIO_WritePin(TRAFFIC_PORT, R2_PIN | Y2_PIN | G2_PIN, GPIO_PIN_RESET);
    } else {
        // Light up group 2
        HAL_GPIO_WritePin(TRAFFIC_PORT, R1_PIN | Y1_PIN | G1_PIN, GPIO_PIN_RESET);
        HAL_GPIO_WritePin(TRAFFIC_PORT, R2_PIN | Y2_PIN | G2_PIN, GPIO_PIN_SET);
    }
}

// LED sequential lighting task (for PB9 interrupt)
void LED_Sequential_Task(void) {
    uint32_t elapsed = HAL_GetTick() - interrupt_start_time;
    
    if (elapsed >= 1800) {
        // After 1.8 seconds (800ms for lighting + 1000ms hold), turn off all LEDs and finish
        HAL_GPIO_WritePin(LED_PORT, 0xFF, GPIO_PIN_RESET);
        pb9_interrupt_active = 0;
        
        // If PB12 was preempted, restore it
        if (pb12_was_preempted) {
            pb12_interrupt_active = 1;
            pb12_was_preempted = 0;
            // Adjust interrupt_start_time to account for elapsed time before preemption
            interrupt_start_time = HAL_GetTick() - pb12_elapsed_before_preempt;
        }
        return;
    }
    
    uint8_t led_count = elapsed / 100;
    
    if (led_count >= 8) {
        // All LEDs on, keep them on until total time reaches 1800ms
        HAL_GPIO_WritePin(LED_PORT, LED1_PIN | LED2_PIN | LED3_PIN | LED4_PIN | 
                         LED5_PIN | LED6_PIN | LED7_PIN | LED8_PIN, GPIO_PIN_SET);
        return;
    }
    
    // Light up LEDs sequentially
    uint16_t led_mask = 0;
    for (uint8_t i = 0; i <= led_count; i++) {
        led_mask |= (1 << i);
    }
    
    HAL_GPIO_WritePin(LED_PORT, 0xFF, GPIO_PIN_RESET); // Turn off all LEDs
    HAL_GPIO_WritePin(LED_PORT, led_mask, GPIO_PIN_SET); // Turn on required LEDs
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
  MX_TIM3_Init();
  /* USER CODE BEGIN 2 */
  HAL_TIM_Base_Start(&htim3);
  last_update_time = HAL_GetTick();
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
    // Handle PB9 interrupt (highest priority)
    if (pb9_interrupt_active) {
        LED_Sequential_Task();
        last_update_time = HAL_GetTick(); // Pause digit counter during interrupt
        continue; // Skip other tasks while LED task is active
    }
    
    // Handle PB12 interrupt
    if (pb12_interrupt_active) {
        Traffic_Light_Task();
        last_update_time = HAL_GetTick(); // Pause digit counter during interrupt
        continue; // Skip digit display while traffic light is active
    }
    
    // Normal operation: display digit counting 0-9
    uint32_t current_time = HAL_GetTick();
    if (current_time - last_update_time >= 1000) {
        current_digit++;
        if (current_digit > 9) {
            current_digit = 0;
        }
        last_update_time = current_time;
    }
    
    Display_Digit(current_digit);
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

/* USER CODE BEGIN 4 */
// GPIO EXTI Callback
void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin) {
    if (GPIO_Pin == GPIO_PIN_12) {
        // PB12 pressed - start traffic light blinking
        if (!pb9_interrupt_active && !pb12_was_preempted) { // Only if not preempted by PB9
            pb12_interrupt_active = 1;
            interrupt_start_time = HAL_GetTick();
            // Turn off all LEDs
            HAL_GPIO_WritePin(LED_PORT, 0xFF, GPIO_PIN_RESET);
        }
    } else if (GPIO_Pin == GPIO_PIN_9) {
        // PB9 pressed - preempt traffic light, start LED sequence
        pb9_interrupt_active = 1;
        
        // Save PB12 state if it was active
        if (pb12_interrupt_active) {
            pb12_was_preempted = 1;
            pb12_elapsed_before_preempt = HAL_GetTick() - interrupt_start_time;
            pb12_interrupt_active = 0; // Temporarily stop PB12
        }
        
        interrupt_start_time = HAL_GetTick();
        // Turn off all traffic lights
        HAL_GPIO_WritePin(TRAFFIC_PORT, R1_PIN | Y1_PIN | G1_PIN | R2_PIN | Y2_PIN | G2_PIN, GPIO_PIN_RESET);
        // Turn off all LEDs initially
        HAL_GPIO_WritePin(LED_PORT, 0xFF, GPIO_PIN_RESET);
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
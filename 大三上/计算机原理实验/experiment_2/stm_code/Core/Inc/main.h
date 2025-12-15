/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.h
  * @brief          : Header for main.c file.
  *                   This file contains the common defines of the application.
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

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __MAIN_H
#define __MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "stm32f4xx_hal.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <stdint.h>
/* USER CODE END Includes */

/* Exported types ------------------------------------------------------------*/
/* USER CODE BEGIN ET */
typedef struct {
    uint8_t write_mode;      // SW0: 0=读出, 1=写入
    uint8_t ram_select;      // SW1: 0=RAM0, 1=RAM1
    uint8_t data_to_write;   // SW2,SW3: 待写入数据(0-3)
    uint8_t addr;            // SW4,SW5: 地址(0-3)
    uint8_t ram0_data;       // 从RAM0读取的数据
    uint8_t ram1_data;       // 从RAM1读取的数据
} SystemState_t;
/* USER CODE END ET */

/* Exported constants --------------------------------------------------------*/
/* USER CODE BEGIN EC */

/* USER CODE END EC */

/* Exported macro ------------------------------------------------------------*/
/* USER CODE BEGIN EM */

/* USER CODE END EM */

/* Exported functions prototypes ---------------------------------------------*/
void Error_Handler(void);

/* USER CODE BEGIN EFP */
void HC595_SendByte(uint8_t data);
void HC138_Select(uint8_t digit);
void Display_Digit(uint8_t digit, uint8_t value);
void Update_Display(void);
void Read_Switches(void);
void Update_LEDs(void);
void RAM_Write(uint8_t ram_sel, uint8_t addr, uint8_t data);
void RAM_Read(uint8_t ram_sel, uint8_t addr);
void RAM_Init(void);
/* USER CODE END EFP */

/* Private defines -----------------------------------------------------------*/

/* USER CODE BEGIN Private defines */
// 74HC595引脚定义 (数码管段选)
#define HC595_SI_PIN    GPIO_PIN_0
#define HC595_SI_PORT   GPIOA
#define HC595_RCK_PIN   GPIO_PIN_1
#define HC595_RCK_PORT  GPIOA
#define HC595_SCK_PIN   GPIO_PIN_2
#define HC595_SCK_PORT  GPIOA

// 74HC138引脚定义 (数码管位选)
#define HC138_A_PIN     GPIO_PIN_3
#define HC138_A_PORT    GPIOA
#define HC138_B_PIN     GPIO_PIN_4
#define HC138_B_PORT    GPIOA
#define HC138_C_PIN     GPIO_PIN_5
#define HC138_C_PORT    GPIOA

// LED引脚定义 (PB0-PB7)
#define LED_PORT        GPIOB

// 拨码开关引脚定义 (PC0-PC7)
#define SW_PORT         GPIOC

// 双RAM引脚定义 (连接到PF端口)
#define RAM_CLKA_PIN    GPIO_PIN_6
#define RAM_CLKA_PORT   GPIOF
#define RAM_CLKB_PIN    GPIO_PIN_14
#define RAM_CLKB_PORT   GPIOF

#define RAM_ENA_PIN     GPIO_PIN_1
#define RAM_ENA_PORT    GPIOF
#define RAM_ENB_PIN     GPIO_PIN_9
#define RAM_ENB_PORT    GPIOF

#define RAM_WEA_PIN     GPIO_PIN_0
#define RAM_WEA_PORT    GPIOF
#define RAM_WEB_PIN     GPIO_PIN_8
#define RAM_WEB_PORT    GPIOF

#define RAM_ADDRA_PIN   GPIO_PIN_7
#define RAM_ADDRA_PORT  GPIOF
#define RAM_ADDRB_PIN   GPIO_PIN_15
#define RAM_ADDRB_PORT  GPIOF

#define RAM_DIA0_PIN    GPIO_PIN_4
#define RAM_DIA0_PORT   GPIOF
#define RAM_DIA1_PIN    GPIO_PIN_5
#define RAM_DIA1_PORT   GPIOF
#define RAM_DIB0_PIN    GPIO_PIN_12
#define RAM_DIB0_PORT   GPIOF
#define RAM_DIB1_PIN    GPIO_PIN_13
#define RAM_DIB1_PORT   GPIOF

#define RAM_DOA0_PIN    GPIO_PIN_2
#define RAM_DOA0_PORT   GPIOF
#define RAM_DOA1_PIN    GPIO_PIN_3
#define RAM_DOA1_PORT   GPIOF
#define RAM_DOB0_PIN    GPIO_PIN_10
#define RAM_DOB0_PORT   GPIOF
#define RAM_DOB1_PIN    GPIO_PIN_11
#define RAM_DOB1_PORT   GPIOF

// 数码管段码表 (共阴数码管)
extern const uint8_t DigitCode[];
/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */

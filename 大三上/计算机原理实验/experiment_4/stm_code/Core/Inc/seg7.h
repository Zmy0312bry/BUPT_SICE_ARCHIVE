/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : seg7.h
  * @brief          : Header for seg7.c file.
  *                   7-segment display driver using 74HC595 and 74HC138
  ******************************************************************************
  */
/* USER CODE END Header */

#ifndef __SEG7_H
#define __SEG7_H

#ifdef __cplusplus
extern "C" {
#endif

#include "stm32f4xx_hal.h"
#include <stdint.h>

/* 74HC595 Control Pins */
#define SEG7_SI_PIN     GPIO_PIN_0
#define SEG7_SI_PORT    GPIOF
#define SEG7_RCK_PIN    GPIO_PIN_1
#define SEG7_RCK_PORT   GPIOF
#define SEG7_SCK_PIN    GPIO_PIN_2
#define SEG7_SCK_PORT   GPIOF

/* 74HC138 Control Pins (for digit selection) */
#define SEG7_A_PIN      GPIO_PIN_3
#define SEG7_A_PORT     GPIOF
#define SEG7_B_PIN      GPIO_PIN_4
#define SEG7_B_PORT     GPIOF
#define SEG7_C_PIN      GPIO_PIN_5
#define SEG7_C_PORT     GPIOF

/* Number of digits */
#define SEG7_NUM_DIGITS 8

/* Pin operations */
#define SEG7_SI_LOW     HAL_GPIO_WritePin(SEG7_SI_PORT, SEG7_SI_PIN, GPIO_PIN_RESET)
#define SEG7_SI_HIGH    HAL_GPIO_WritePin(SEG7_SI_PORT, SEG7_SI_PIN, GPIO_PIN_SET)
#define SEG7_RCK_LOW    HAL_GPIO_WritePin(SEG7_RCK_PORT, SEG7_RCK_PIN, GPIO_PIN_RESET)
#define SEG7_RCK_HIGH   HAL_GPIO_WritePin(SEG7_RCK_PORT, SEG7_RCK_PIN, GPIO_PIN_SET)
#define SEG7_SCK_LOW    HAL_GPIO_WritePin(SEG7_SCK_PORT, SEG7_SCK_PIN, GPIO_PIN_RESET)
#define SEG7_SCK_HIGH   HAL_GPIO_WritePin(SEG7_SCK_PORT, SEG7_SCK_PIN, GPIO_PIN_SET)

/* Function Prototypes */
void SEG7_Init(void);
void SEG7_WriteDigit(uint8_t digit, uint8_t value);
void SEG7_SetDigit(uint8_t digit, uint8_t seg_code);
void SEG7_DisplayNumber(uint32_t number);
void SEG7_Clear(void);
void SEG7_AllOn(void);
void SEG7_Refresh(void);
void SEG7_SetBuffer(uint8_t digit, uint8_t value);

#ifdef __cplusplus
}
#endif

#endif /* __SEG7_H */
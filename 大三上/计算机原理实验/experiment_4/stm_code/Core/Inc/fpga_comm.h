/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : fpga_comm.h
  * @brief          : Header for fpga_comm.c file.
  *                   FPGA communication driver for handwriting recognition
  ******************************************************************************
  */
/* USER CODE END Header */

#ifndef __FPGA_COMM_H
#define __FPGA_COMM_H

#ifdef __cplusplus
extern "C" {
#endif

#include "stm32f4xx_hal.h"
#include <stdint.h>
#include <stdbool.h>

/* FPGA Control Pins */
#define FPGA_RST_PIN        GPIO_PIN_0
#define FPGA_RST_PORT       GPIOC
#define FPGA_DATA_IN_PIN    GPIO_PIN_1
#define FPGA_DATA_IN_PORT   GPIOC
#define FPGA_CLK_PIN        GPIO_PIN_2
#define FPGA_CLK_PORT       GPIOC

/* FPGA Status Pins */
#define FPGA_RESULT_VALID_PIN   GPIO_PIN_3
#define FPGA_RESULT_VALID_PORT  GPIOC
#define FPGA_BUSY_PIN           GPIO_PIN_8
#define FPGA_BUSY_PORT          GPIOC

/* FPGA Data Output Pins (PC4-PC7) */
#define FPGA_DATA_OUT_PORT  GPIOC
#define FPGA_DATA_OUT_MASK  0xF0  // Bits 4-7

/* Pin operations */
#define FPGA_RST_LOW        HAL_GPIO_WritePin(FPGA_RST_PORT, FPGA_RST_PIN, GPIO_PIN_RESET)
#define FPGA_RST_HIGH       HAL_GPIO_WritePin(FPGA_RST_PORT, FPGA_RST_PIN, GPIO_PIN_SET)
#define FPGA_DATA_IN_LOW    HAL_GPIO_WritePin(FPGA_DATA_IN_PORT, FPGA_DATA_IN_PIN, GPIO_PIN_RESET)
#define FPGA_DATA_IN_HIGH   HAL_GPIO_WritePin(FPGA_DATA_IN_PORT, FPGA_DATA_IN_PIN, GPIO_PIN_SET)
#define FPGA_CLK_LOW        HAL_GPIO_WritePin(FPGA_CLK_PORT, FPGA_CLK_PIN, GPIO_PIN_RESET)
#define FPGA_CLK_HIGH       HAL_GPIO_WritePin(FPGA_CLK_PORT, FPGA_CLK_PIN, GPIO_PIN_SET)

#define FPGA_IS_BUSY        (HAL_GPIO_ReadPin(FPGA_BUSY_PORT, FPGA_BUSY_PIN) == GPIO_PIN_SET)
#define FPGA_IS_RESULT_VALID (HAL_GPIO_ReadPin(FPGA_RESULT_VALID_PORT, FPGA_RESULT_VALID_PIN) == GPIO_PIN_SET)

/* FPGA State */
typedef enum {
    FPGA_STATE_IDLE = 0,
    FPGA_STATE_SENDING,
    FPGA_STATE_COMPUTING,
    FPGA_STATE_DONE
} FPGA_State_t;

/* Data size */
#define FPGA_DATA_SIZE  784  // 28x28 pixels

/* Function Prototypes */
void FPGA_Init(void);
void FPGA_Reset(void);
void FPGA_StartSend(const uint8_t *data, uint16_t len);
void FPGA_ClockTick(void);
uint8_t FPGA_ReadResult(void);
FPGA_State_t FPGA_GetState(void);
void FPGA_SetState(FPGA_State_t state);
bool FPGA_IsBusy(void);
bool FPGA_IsResultValid(void);
void FPGA_SetData(const uint8_t *data);
const uint8_t* FPGA_GetData(void);

/* Debug and status functions */
void FPGA_PrintIOStatus(void);
void FPGA_PrintDetailedStatus(void);
const char* FPGA_GetStateName(FPGA_State_t state);

#ifdef __cplusplus
}
#endif

#endif /* __FPGA_COMM_H */
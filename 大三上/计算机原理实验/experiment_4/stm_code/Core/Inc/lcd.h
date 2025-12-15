/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : lcd.h
  * @brief          : Header for lcd.c file.
  *                   LCD driver for ILI9341
  ******************************************************************************
  */
/* USER CODE END Header */

#ifndef __LCD_H
#define __LCD_H

#ifdef __cplusplus
extern "C" {
#endif

#include "stm32f4xx_hal.h"
#include <stdint.h>

/* LCD Configuration */
#define LCD_DIRECTION 1  // 1:竖屏 2:横屏

/* LCD Size */
#if LCD_DIRECTION == 1
#define LCD_WIDTH  320
#define LCD_HEIGHT 480
#else
#define LCD_WIDTH  480
#define LCD_HEIGHT 320
#endif

/* LCD Commands */
#define LCD_CMD_SETxOrgin  0x2A
#define LCD_CMD_SETyOrgin  0x2B
#define LCD_CMD_WRgram     0x2C

/* LCD Colors */
typedef uint16_t LCD_Color_t;

#define LCD_COLOR_WHITE   0xFFFF
#define LCD_COLOR_BLACK   0x0000
#define LCD_COLOR_RED     0xF800
#define LCD_COLOR_GREEN   0x07E0
#define LCD_COLOR_BLUE    0x001F
#define LCD_COLOR_YELLOW  0xFFE0
#define LCD_COLOR_CYAN    0x07FF
#define LCD_COLOR_MAGENTA 0xF81F
#define LCD_COLOR_GRAY    0x8410

/* FSMC LCD Address */
#define LCD_BASE        ((uint32_t)(0x60000000 | 0x0C000000))
#define LCD_CMD_ADDR    (*((volatile uint16_t *)(LCD_BASE)))
#define LCD_DATA_ADDR   (*((volatile uint16_t *)(LCD_BASE + (1 << (6 + 1)))))

/* LCD Control Pins */
#define LCD_RST_PIN     GPIO_PIN_2
#define LCD_RST_PORT    GPIOB
#define LCD_BL_PIN      GPIO_PIN_0
#define LCD_BL_PORT     GPIOB

#define LCD_RST_LOW     HAL_GPIO_WritePin(LCD_RST_PORT, LCD_RST_PIN, GPIO_PIN_RESET)
#define LCD_RST_HIGH    HAL_GPIO_WritePin(LCD_RST_PORT, LCD_RST_PIN, GPIO_PIN_SET)
#define LCD_BL_ON       HAL_GPIO_WritePin(LCD_BL_PORT, LCD_BL_PIN, GPIO_PIN_RESET)
#define LCD_BL_OFF      HAL_GPIO_WritePin(LCD_BL_PORT, LCD_BL_PIN, GPIO_PIN_SET)

/* LCD Write/Read Operations */
#define LCD_Write_CMD(cmd)   do { LCD_CMD_ADDR = (cmd); } while(0)
#define LCD_Write_DATA(data) do { LCD_DATA_ADDR = (data); } while(0)
#define LCD_Read_DATA()      (LCD_DATA_ADDR)

/* LCD Structure */
typedef struct {
    uint32_t ID;
    void (*Init)(void);
    void (*FillColor)(uint16_t x, uint16_t y, uint16_t w, uint16_t h, LCD_Color_t color);
    void (*DrawPixel)(uint16_t x, uint16_t y, LCD_Color_t color);
    void (*DrawChar)(uint16_t x, uint16_t y, char c, LCD_Color_t fg, LCD_Color_t bg);
    void (*DrawString)(uint16_t x, uint16_t y, const char *str, LCD_Color_t fg, LCD_Color_t bg);
    void (*Clear)(LCD_Color_t color);
    void (*DisplayDigit)(const uint8_t *digit_data);
} TFT_LCD_t;

/* External LCD Object */
extern TFT_LCD_t TFT_LCD;

/* Function Prototypes */
void LCD_Init(void);
void LCD_FillColor(uint16_t x, uint16_t y, uint16_t w, uint16_t h, LCD_Color_t color);
void LCD_DrawPixel(uint16_t x, uint16_t y, LCD_Color_t color);
void LCD_DrawChar(uint16_t x, uint16_t y, char c, LCD_Color_t fg, LCD_Color_t bg);
void LCD_DrawString(uint16_t x, uint16_t y, const char *str, LCD_Color_t fg, LCD_Color_t bg);
void LCD_Clear(LCD_Color_t color);
void LCD_DisplayDigit(const uint8_t *digit_data);
void LCD_DisplayTestPattern(void);

#ifdef __cplusplus
}
#endif

#endif /* __LCD_H */
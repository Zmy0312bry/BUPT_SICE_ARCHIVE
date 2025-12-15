/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : lcd.c
  * @brief          : LCD driver implementation for ILI9341
  ******************************************************************************
  */
/* USER CODE END Header */

#include "lcd.h"
#include <string.h>
#include <stdio.h>

/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Private function prototypes */
static uint32_t LCD_ReadID(void);
static void LCD_Disp_Direction(void);
static void LCD_SetWindows(uint16_t x, uint16_t y, uint16_t w, uint16_t h);
static void LCD_Init_Internal(void);
static void LCD_FillColor_Internal(uint16_t x, uint16_t y, uint16_t w, uint16_t h, LCD_Color_t color);
static void LCD_DrawPixel_Internal(uint16_t x, uint16_t y, LCD_Color_t color);
static void LCD_DrawChar_Internal(uint16_t x, uint16_t y, char c, LCD_Color_t fg, LCD_Color_t bg);
static void LCD_DrawString_Internal(uint16_t x, uint16_t y, const char *str, LCD_Color_t fg, LCD_Color_t bg);
static void LCD_Clear_Internal(LCD_Color_t color);
static void LCD_DisplayDigit_Internal(const uint8_t *digit_data);
static void LCD_DisplayTestPattern_Internal(void);

/* USER CODE BEGIN PV */

/* USER CODE END PV */

/* LCD Object */
TFT_LCD_t TFT_LCD = {
    0,
    LCD_Init_Internal,
    LCD_FillColor_Internal,
    LCD_DrawPixel_Internal,
    LCD_DrawChar_Internal,
    LCD_DrawString_Internal,
    LCD_Clear_Internal,
    LCD_DisplayDigit_Internal,
    LCD_DisplayTestPattern_Internal
};

/* Simple 8x8 font */
static const uint8_t font8x8[96][8] = {
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // ' '
    {0x18, 0x3C, 0x3C, 0x18, 0x18, 0x00, 0x18, 0x00}, // '!'
    {0x36, 0x36, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // '"'
    {0x36, 0x36, 0x7F, 0x36, 0x7F, 0x36, 0x36, 0x00}, // '#'
    {0x0C, 0x3E, 0x03, 0x1E, 0x30, 0x1F, 0x0C, 0x00}, // '$'
    {0x00, 0x63, 0x33, 0x18, 0x0C, 0x66, 0x63, 0x00}, // '%'
    {0x1C, 0x36, 0x1C, 0x6E, 0x3B, 0x33, 0x6E, 0x00}, // '&'
    {0x06, 0x06, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00}, // '''
    {0x18, 0x0C, 0x06, 0x06, 0x06, 0x0C, 0x18, 0x00}, // '('
    {0x06, 0x0C, 0x18, 0x18, 0x18, 0x0C, 0x06, 0x00}, // ')'
    {0x00, 0x66, 0x3C, 0xFF, 0x3C, 0x66, 0x00, 0x00}, // '*'
    {0x00, 0x0C, 0x0C, 0x3F, 0x0C, 0x0C, 0x00, 0x00}, // '+'
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x0C, 0x06}, // ','
    {0x00, 0x00, 0x00, 0x3F, 0x00, 0x00, 0x00, 0x00}, // '-'
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x0C, 0x00}, // '.'
    {0x60, 0x30, 0x18, 0x0C, 0x06, 0x03, 0x01, 0x00}, // '/'
    {0x3E, 0x63, 0x73, 0x7B, 0x6F, 0x67, 0x3E, 0x00}, // '0'
    {0x0C, 0x0E, 0x0C, 0x0C, 0x0C, 0x0C, 0x3F, 0x00}, // '1'
    {0x1E, 0x33, 0x30, 0x1C, 0x06, 0x33, 0x3F, 0x00}, // '2'
    {0x1E, 0x33, 0x30, 0x1C, 0x30, 0x33, 0x1E, 0x00}, // '3'
    {0x38, 0x3C, 0x36, 0x33, 0x7F, 0x30, 0x78, 0x00}, // '4'
    {0x3F, 0x03, 0x1F, 0x30, 0x30, 0x33, 0x1E, 0x00}, // '5'
    {0x1C, 0x06, 0x03, 0x1F, 0x33, 0x33, 0x1E, 0x00}, // '6'
    {0x3F, 0x33, 0x30, 0x18, 0x0C, 0x0C, 0x0C, 0x00}, // '7'
    {0x1E, 0x33, 0x33, 0x1E, 0x33, 0x33, 0x1E, 0x00}, // '8'
    {0x1E, 0x33, 0x33, 0x3E, 0x30, 0x18, 0x0E, 0x00}, // '9'
    {0x00, 0x0C, 0x0C, 0x00, 0x00, 0x0C, 0x0C, 0x00}, // ':'
    {0x00, 0x0C, 0x0C, 0x00, 0x00, 0x0C, 0x0C, 0x06}, // ';'
    {0x18, 0x0C, 0x06, 0x03, 0x06, 0x0C, 0x18, 0x00}, // '<'
    {0x00, 0x00, 0x3F, 0x00, 0x00, 0x3F, 0x00, 0x00}, // '='
    {0x06, 0x0C, 0x18, 0x30, 0x18, 0x0C, 0x06, 0x00}, // '>'
    {0x1E, 0x33, 0x30, 0x18, 0x0C, 0x00, 0x0C, 0x00}, // '?'
    {0x3E, 0x63, 0x7B, 0x7B, 0x7B, 0x03, 0x1E, 0x00}, // '@'
    {0x0C, 0x1E, 0x33, 0x33, 0x3F, 0x33, 0x33, 0x00}, // 'A'
    {0x3F, 0x66, 0x66, 0x3E, 0x66, 0x66, 0x3F, 0x00}, // 'B'
    {0x3C, 0x66, 0x03, 0x03, 0x03, 0x66, 0x3C, 0x00}, // 'C'
    {0x1F, 0x36, 0x66, 0x66, 0x66, 0x36, 0x1F, 0x00}, // 'D'
    {0x7F, 0x46, 0x16, 0x1E, 0x16, 0x46, 0x7F, 0x00}, // 'E'
    {0x7F, 0x46, 0x16, 0x1E, 0x16, 0x06, 0x0F, 0x00}, // 'F'
    {0x3C, 0x66, 0x03, 0x03, 0x73, 0x66, 0x7C, 0x00}, // 'G'
    {0x33, 0x33, 0x33, 0x3F, 0x33, 0x33, 0x33, 0x00}, // 'H'
    {0x1E, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x1E, 0x00}, // 'I'
    {0x78, 0x30, 0x30, 0x30, 0x33, 0x33, 0x1E, 0x00}, // 'J'
    {0x67, 0x66, 0x36, 0x1E, 0x36, 0x66, 0x67, 0x00}, // 'K'
    {0x0F, 0x06, 0x06, 0x06, 0x46, 0x66, 0x7F, 0x00}, // 'L'
    {0x63, 0x77, 0x7F, 0x7F, 0x6B, 0x63, 0x63, 0x00}, // 'M'
    {0x63, 0x67, 0x6F, 0x7B, 0x73, 0x63, 0x63, 0x00}, // 'N'
    {0x1C, 0x36, 0x63, 0x63, 0x63, 0x36, 0x1C, 0x00}, // 'O'
    {0x3F, 0x66, 0x66, 0x3E, 0x06, 0x06, 0x0F, 0x00}, // 'P'
    {0x1E, 0x33, 0x33, 0x33, 0x3B, 0x1E, 0x38, 0x00}, // 'Q'
    {0x3F, 0x66, 0x66, 0x3E, 0x36, 0x66, 0x67, 0x00}, // 'R'
    {0x1E, 0x33, 0x07, 0x0E, 0x38, 0x33, 0x1E, 0x00}, // 'S'
    {0x3F, 0x2D, 0x0C, 0x0C, 0x0C, 0x0C, 0x1E, 0x00}, // 'T'
    {0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x3F, 0x00}, // 'U'
    {0x33, 0x33, 0x33, 0x33, 0x33, 0x1E, 0x0C, 0x00}, // 'V'
    {0x63, 0x63, 0x63, 0x6B, 0x7F, 0x77, 0x63, 0x00}, // 'W'
    {0x63, 0x63, 0x36, 0x1C, 0x1C, 0x36, 0x63, 0x00}, // 'X'
    {0x33, 0x33, 0x33, 0x1E, 0x0C, 0x0C, 0x1E, 0x00}, // 'Y'
    {0x7F, 0x63, 0x31, 0x18, 0x4C, 0x66, 0x7F, 0x00}, // 'Z'
    {0x1E, 0x06, 0x06, 0x06, 0x06, 0x06, 0x1E, 0x00}, // '['
    {0x03, 0x06, 0x0C, 0x18, 0x30, 0x60, 0x40, 0x00}, // '\'
    {0x1E, 0x18, 0x18, 0x18, 0x18, 0x18, 0x1E, 0x00}, // ']'
    {0x08, 0x1C, 0x36, 0x63, 0x00, 0x00, 0x00, 0x00}, // '^'
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF}, // '_'
    {0x0C, 0x0C, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00}, // '`'
    {0x00, 0x00, 0x1E, 0x30, 0x3E, 0x33, 0x6E, 0x00}, // 'a'
    {0x07, 0x06, 0x06, 0x3E, 0x66, 0x66, 0x3B, 0x00}, // 'b'
    {0x00, 0x00, 0x1E, 0x33, 0x03, 0x33, 0x1E, 0x00}, // 'c'
    {0x38, 0x30, 0x30, 0x3e, 0x33, 0x33, 0x6E, 0x00}, // 'd'
    {0x00, 0x00, 0x1E, 0x33, 0x3f, 0x03, 0x1E, 0x00}, // 'e'
    {0x1C, 0x36, 0x06, 0x0f, 0x06, 0x06, 0x0F, 0x00}, // 'f'
    {0x00, 0x00, 0x6E, 0x33, 0x33, 0x3E, 0x30, 0x1F}, // 'g'
    {0x07, 0x06, 0x36, 0x6E, 0x66, 0x66, 0x67, 0x00}, // 'h'
    {0x0C, 0x00, 0x0E, 0x0C, 0x0C, 0x0C, 0x1E, 0x00}, // 'i'
    {0x30, 0x00, 0x30, 0x30, 0x30, 0x33, 0x33, 0x1E}, // 'j'
    {0x07, 0x06, 0x66, 0x36, 0x1E, 0x36, 0x67, 0x00}, // 'k'
    {0x0E, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x1E, 0x00}, // 'l'
    {0x00, 0x00, 0x33, 0x7F, 0x7F, 0x6B, 0x63, 0x00}, // 'm'
    {0x00, 0x00, 0x1F, 0x33, 0x33, 0x33, 0x33, 0x00}, // 'n'
    {0x00, 0x00, 0x1E, 0x33, 0x33, 0x33, 0x1E, 0x00}, // 'o'
    {0x00, 0x00, 0x3B, 0x66, 0x66, 0x3E, 0x06, 0x0F}, // 'p'
    {0x00, 0x00, 0x6E, 0x33, 0x33, 0x3E, 0x30, 0x78}, // 'q'
    {0x00, 0x00, 0x3B, 0x6E, 0x66, 0x06, 0x0F, 0x00}, // 'r'
    {0x00, 0x00, 0x3E, 0x03, 0x1E, 0x30, 0x1F, 0x00}, // 's'
    {0x08, 0x0C, 0x3E, 0x0C, 0x0C, 0x2C, 0x18, 0x00}, // 't'
    {0x00, 0x00, 0x33, 0x33, 0x33, 0x33, 0x6E, 0x00}, // 'u'
    {0x00, 0x00, 0x33, 0x33, 0x33, 0x1E, 0x0C, 0x00}, // 'v'
    {0x00, 0x00, 0x63, 0x6B, 0x7F, 0x7F, 0x36, 0x00}, // 'w'
    {0x00, 0x00, 0x63, 0x36, 0x1C, 0x36, 0x63, 0x00}, // 'x'
    {0x00, 0x00, 0x33, 0x33, 0x33, 0x3E, 0x30, 0x1F}, // 'y'
    {0x00, 0x00, 0x3F, 0x19, 0x0C, 0x26, 0x3F, 0x00}, // 'z'
    {0x38, 0x0C, 0x0C, 0x07, 0x0C, 0x0C, 0x38, 0x00}, // '{'
    {0x18, 0x18, 0x18, 0x00, 0x18, 0x18, 0x18, 0x00}, // '|'
    {0x07, 0x0C, 0x0C, 0x38, 0x0C, 0x0C, 0x07, 0x00}, // '}'
    {0x6E, 0x3B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // '~'
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}  // DEL
};

/**
  * @brief  Read LCD ID
  * @retval LCD ID
  */
static uint32_t LCD_ReadID(void)
{
    uint32_t LCD_ID = 0;
    uint32_t buf[4];
    
    LCD_Write_CMD(0xD3);
    buf[0] = LCD_Read_DATA();        // First read is invalid
    buf[1] = LCD_Read_DATA() & 0x00FF;
    buf[2] = LCD_Read_DATA() & 0x00FF;
    buf[3] = LCD_Read_DATA() & 0x00FF;
    
    LCD_ID = (buf[1] << 16) + (buf[2] << 8) + buf[3];
    return LCD_ID;
}

/**
  * @brief  Initialize LCD
  */
static void LCD_Init_Internal(void)
{
    /* USER CODE BEGIN LCD_Init_Internal */
    
    // Turn on backlight FIRST to verify it's working
    LCD_BL_ON;
    HAL_Delay(50);
    
    // Hardware reset
    LCD_RST_LOW;
    HAL_Delay(100);
    LCD_RST_HIGH;
    HAL_Delay(100);
    
    // Read LCD ID
    TFT_LCD.ID = LCD_ReadID();
    
    // Print LCD ID for debugging
    extern int UART_Printf(const char *fmt, ...);
    UART_Printf("[DEBUG] LCD ID read: 0x%06lX\r\n", TFT_LCD.ID);
    
    if (TFT_LCD.ID == 0x9341) {
        UART_Printf("[DEBUG] LCD ID: ILI9341\r\n");
    } else if (TFT_LCD.ID == 0x9486) {
        UART_Printf("[DEBUG] LCD ID: ILI9486\r\n");
    } else if (TFT_LCD.ID == 0x000000 || TFT_LCD.ID == 0xFFFFFF) {
        UART_Printf("[ERROR] LCD ID invalid! FSMC not communicating?\r\n");
        UART_Printf("[ERROR] Check FSMC data/control lines\r\n");
    } else {
        UART_Printf("[WARNING] Unknown LCD ID: 0x%06lX\r\n", TFT_LCD.ID);
    }
    
    // Initialize based on LCD ID
    if (TFT_LCD.ID == 0x9486) {
        // ILI9486 initialization
        UART_Printf("[DEBUG] Using ILI9486 init sequence\r\n");
        
        LCD_Write_CMD(0xF1);
        LCD_Write_DATA(0x36);
        LCD_Write_DATA(0x04);
        LCD_Write_DATA(0x00);
        LCD_Write_DATA(0x3C);
        LCD_Write_DATA(0x0F);
        LCD_Write_DATA(0x8F);
        
        LCD_Write_CMD(0xF2);
        LCD_Write_DATA(0x18);
        LCD_Write_DATA(0xA3);
        LCD_Write_DATA(0x12);
        LCD_Write_DATA(0x02);
        LCD_Write_DATA(0xB2);
        LCD_Write_DATA(0x12);
        LCD_Write_DATA(0xFF);
        LCD_Write_DATA(0x10);
        LCD_Write_DATA(0x00);
        
        LCD_Write_CMD(0xF8);
        LCD_Write_DATA(0x21);
        LCD_Write_DATA(0x04);
        
        LCD_Write_CMD(0xF9);
        LCD_Write_DATA(0x00);
        LCD_Write_DATA(0x08);
        
        LCD_Write_CMD(0xC0);    // Power Control 1
        LCD_Write_DATA(0x0F);
        LCD_Write_DATA(0x0F);
        
        LCD_Write_CMD(0xC1);    // Power Control 2
        LCD_Write_DATA(0x42);
        
        LCD_Write_CMD(0xC2);    // Power Control 3
        LCD_Write_DATA(0x22);
        
        LCD_Write_CMD(0xC5);    // VCOM Control
        LCD_Write_DATA(0x00);
        LCD_Write_DATA(0x3E);
        LCD_Write_DATA(0x80);
        
        LCD_Write_CMD(0xB1);    // Frame Rate Control
        LCD_Write_DATA(0xB0);
        LCD_Write_DATA(0x11);
        
        LCD_Write_CMD(0xB4);    // Display Inversion Control
        LCD_Write_DATA(0x02);
        
        LCD_Write_CMD(0xB6);    // Display Function Control
        LCD_Write_DATA(0x02);
        LCD_Write_DATA(0x22);
        LCD_Write_DATA(0x3B);
        
        LCD_Write_CMD(0xB7);
        LCD_Write_DATA(0xC6);
        
        LCD_Write_CMD(0xE0);    // Positive Gamma Control
        LCD_Write_DATA(0x0F);
        LCD_Write_DATA(0x1F);
        LCD_Write_DATA(0x1C);
        LCD_Write_DATA(0x0C);
        LCD_Write_DATA(0x0F);
        LCD_Write_DATA(0x08);
        LCD_Write_DATA(0x48);
        LCD_Write_DATA(0x98);
        LCD_Write_DATA(0x37);
        LCD_Write_DATA(0x0A);
        LCD_Write_DATA(0x13);
        LCD_Write_DATA(0x04);
        LCD_Write_DATA(0x11);
        LCD_Write_DATA(0x0D);
        LCD_Write_DATA(0x00);
        
        LCD_Write_CMD(0xE1);    // Negative Gamma Control
        LCD_Write_DATA(0x0F);
        LCD_Write_DATA(0x32);
        LCD_Write_DATA(0x2E);
        LCD_Write_DATA(0x0B);
        LCD_Write_DATA(0x0D);
        LCD_Write_DATA(0x05);
        LCD_Write_DATA(0x47);
        LCD_Write_DATA(0x75);
        LCD_Write_DATA(0x37);
        LCD_Write_DATA(0x06);
        LCD_Write_DATA(0x10);
        LCD_Write_DATA(0x03);
        LCD_Write_DATA(0x24);
        LCD_Write_DATA(0x20);
        LCD_Write_DATA(0x00);
        
        LCD_Disp_Direction();   // Set LCD display direction
        
        LCD_Write_CMD(0x3A);    // Pixel Format Set
        LCD_Write_DATA(0x55);   // 16-bit/pixel (RGB565)
        
        LCD_Write_CMD(0x11);    // Exit Sleep
        HAL_Delay(120);
        
        LCD_Write_CMD(0x29);    // Display ON
        HAL_Delay(25);
        
    } else {
        // ILI9341 initialization (default)
        UART_Printf("[DEBUG] Using ILI9341 init sequence (default)\r\n");
        
        LCD_Write_CMD(0xCF);
        LCD_Write_DATA(0x00);
        LCD_Write_DATA(0xC9);
        LCD_Write_DATA(0x30);
        LCD_Write_CMD(0xED);
        LCD_Write_DATA(0x64);
        LCD_Write_DATA(0x03);
        LCD_Write_DATA(0x12);
        LCD_Write_DATA(0x81);
        LCD_Write_CMD(0xE8);
        LCD_Write_DATA(0x85);
        LCD_Write_DATA(0x10);
        LCD_Write_DATA(0x7A);
        LCD_Write_CMD(0xCB);
        LCD_Write_DATA(0x39);
        LCD_Write_DATA(0x2C);
        LCD_Write_DATA(0x00);
        LCD_Write_DATA(0x34);
        LCD_Write_DATA(0x02);
        LCD_Write_CMD(0xF7);
        LCD_Write_DATA(0x20);
        LCD_Write_CMD(0xEA);
        LCD_Write_DATA(0x00);
        LCD_Write_DATA(0x00);
        LCD_Write_CMD(0xC0);    // Power control
        LCD_Write_DATA(0x1B);   // VRH[5:0]
        LCD_Write_CMD(0xC1);    // Power control
        LCD_Write_DATA(0x00);   // SAP[2:0];BT[3:0]
        LCD_Write_CMD(0xC5);    // VCM control
        LCD_Write_DATA(0x30);
        LCD_Write_DATA(0x30);
        LCD_Write_CMD(0xC7);    // VCM control2
        LCD_Write_DATA(0xB7);
        LCD_Disp_Direction();   // Set LCD display direction
        LCD_Write_CMD(0x3A);
        LCD_Write_DATA(0x55);
        LCD_Write_CMD(0xB1);
        LCD_Write_DATA(0x00);
        LCD_Write_DATA(0x1A);
        LCD_Write_CMD(0xB6);    // Display Function Control
        LCD_Write_DATA(0x0A);
        LCD_Write_DATA(0xA2);
        LCD_Write_CMD(0xF2);    // 3Gamma Function Disable
        LCD_Write_DATA(0x00);
        LCD_Write_CMD(0x26);    // Gamma curve selected
        LCD_Write_DATA(0x01);
        LCD_Write_CMD(0xE0);    // Set Gamma
        LCD_Write_DATA(0x0F);
        LCD_Write_DATA(0x2A);
        LCD_Write_DATA(0x28);
        LCD_Write_DATA(0x08);
        LCD_Write_DATA(0x0E);
        LCD_Write_DATA(0x08);
        LCD_Write_DATA(0x54);
        LCD_Write_DATA(0xA9);
        LCD_Write_DATA(0x43);
        LCD_Write_DATA(0x0A);
        LCD_Write_DATA(0x0F);
        LCD_Write_DATA(0x00);
        LCD_Write_DATA(0x00);
        LCD_Write_DATA(0x00);
        LCD_Write_DATA(0x00);
        LCD_Write_CMD(0xE1);    // Set Gamma
        LCD_Write_DATA(0x00);
        LCD_Write_DATA(0x15);
        LCD_Write_DATA(0x17);
        LCD_Write_DATA(0x07);
        LCD_Write_DATA(0x11);
        LCD_Write_DATA(0x06);
        LCD_Write_DATA(0x2B);
        LCD_Write_DATA(0x56);
        LCD_Write_DATA(0x3C);
        LCD_Write_DATA(0x05);
        LCD_Write_DATA(0x10);
        LCD_Write_DATA(0x0F);
        LCD_Write_DATA(0x3F);
        LCD_Write_DATA(0x3F);
        LCD_Write_DATA(0x0F);
        LCD_Write_CMD(0x2B);
        LCD_Write_DATA(0x00);
        LCD_Write_DATA(0x00);
        LCD_Write_DATA(0x01);
        LCD_Write_DATA(0x3F);
        LCD_Write_CMD(0x2A);
        LCD_Write_DATA(0x00);
        LCD_Write_DATA(0x00);
        LCD_Write_DATA(0x00);
        LCD_Write_DATA(0xEF);
        LCD_Write_CMD(0x11);    // Exit Sleep
        HAL_Delay(120);
        LCD_Write_CMD(0x29);    // Display on
    }
    
    LCD_BL_ON;  // Turn on backlight
    
    /* USER CODE END LCD_Init_Internal */
}

/**
  * @brief  Set LCD display direction
  */
static void LCD_Disp_Direction(void)
{
    /* USER CODE BEGIN LCD_Disp_Direction */
    
    switch(LCD_DIRECTION)
    {
        case 1: LCD_Write_CMD(0x36); LCD_Write_DATA(1<<3); break;
        case 2: LCD_Write_CMD(0x36); LCD_Write_DATA((1<<3)|(1<<5)|(1<<6)); break;
        case 3: LCD_Write_CMD(0x36); LCD_Write_DATA((1<<3)|(1<<7)|(1<<4)|(1<<6)); break;
        case 4: LCD_Write_CMD(0x36); LCD_Write_DATA((1<<3)|(1<<7)|(1<<5)|(1<<4)); break;
        default:LCD_Write_CMD(0x36); LCD_Write_DATA(1<<3); break;
    }
    
    /* USER CODE END LCD_Disp_Direction */
}

/**
  * @brief  Set LCD display window
  */
static void LCD_SetWindows(uint16_t x, uint16_t y, uint16_t w, uint16_t h)
{
    /* USER CODE BEGIN LCD_SetWindows */
    
    LCD_Write_CMD(LCD_CMD_SETxOrgin);
    LCD_Write_DATA(x >> 8);
    LCD_Write_DATA(0x00FF & x);
    LCD_Write_DATA((x + w - 1) >> 8);
    LCD_Write_DATA((x + w - 1) & 0xFF);
    
    LCD_Write_CMD(LCD_CMD_SETyOrgin);
    LCD_Write_DATA(y >> 8);
    LCD_Write_DATA(0x00FF & y);
    LCD_Write_DATA((y + h - 1) >> 8);
    LCD_Write_DATA((y + h - 1) & 0xFF);
    
    LCD_Write_CMD(LCD_CMD_WRgram);
    
    /* USER CODE END LCD_SetWindows */
}

/**
  * @brief  Fill color on LCD
  */
static void LCD_FillColor_Internal(uint16_t x, uint16_t y, uint16_t w, uint16_t h, LCD_Color_t color)
{
    /* USER CODE BEGIN LCD_FillColor_Internal */
    
    uint32_t total_pixels = (uint32_t)w * h;
    
    LCD_SetWindows(x, y, w, h);
    
    for(uint32_t i = 0; i < total_pixels; i++)
    {
        LCD_Write_DATA(color);
    }
    
    /* USER CODE END LCD_FillColor_Internal */
}

/**
  * @brief  Draw pixel on LCD
  */
static void LCD_DrawPixel_Internal(uint16_t x, uint16_t y, LCD_Color_t color)
{
    /* USER CODE BEGIN LCD_DrawPixel_Internal */
    
    LCD_SetWindows(x, y, 1, 1);
    LCD_Write_DATA(color);
    
    /* USER CODE END LCD_DrawPixel_Internal */
}

/**
  * @brief  Draw character on LCD
  */
static void LCD_DrawChar_Internal(uint16_t x, uint16_t y, char c, LCD_Color_t fg, LCD_Color_t bg)
{
    /* USER CODE BEGIN LCD_DrawChar_Internal */
    
    uint8_t char_index = c - ' ';
    if(char_index >= 96) return;
    
    for(int i = 0; i < 8; i++)
    {
        uint8_t line = font8x8[char_index][i];
        for(int j = 0; j < 8; j++)
        {
            if(line & (1 << j))
            {
                LCD_DrawPixel_Internal(x + j, y + i, fg);
            }
            else
            {
                LCD_DrawPixel_Internal(x + j, y + i, bg);
            }
        }
    }
    
    /* USER CODE END LCD_DrawChar_Internal */
}

/**
  * @brief  Draw string on LCD
  */
static void LCD_DrawString_Internal(uint16_t x, uint16_t y, const char *str, LCD_Color_t fg, LCD_Color_t bg)
{
    /* USER CODE BEGIN LCD_DrawString_Internal */
    
    uint16_t pos_x = x;
    uint16_t pos_y = y;
    
    while(*str)
    {
        if(*str == '\n')
        {
            pos_x = x;
            pos_y += 10;
        }
        else
        {
            LCD_DrawChar_Internal(pos_x, pos_y, *str, fg, bg);
            pos_x += 8;
            if(pos_x >= LCD_WIDTH - 8)
            {
                pos_x = x;
                pos_y += 10;
            }
        }
        str++;
    }
    
    /* USER CODE END LCD_DrawString_Internal */
}

/**
  * @brief  Clear LCD with color
  */
static void LCD_Clear_Internal(LCD_Color_t color)
{
    /* USER CODE BEGIN LCD_Clear_Internal */
    
    LCD_FillColor_Internal(0, 0, LCD_WIDTH, LCD_HEIGHT, color);
    
    /* USER CODE END LCD_Clear_Internal */
}

/**
  * @brief  Display 28x28 digit on LCD
  */
static void LCD_DisplayDigit_Internal(const uint8_t *digit_data)
{
    /* USER CODE BEGIN LCD_DisplayDigit_Internal */
    
    uint16_t start_x = (LCD_WIDTH - 28*4) / 2;   // Center horizontally (scale 4x)
    uint16_t start_y = (LCD_HEIGHT - 28*4) / 2;  // Center vertically (scale 4x)
    
    // Clear screen with white background
    LCD_Clear_Internal(LCD_COLOR_WHITE);
    
    // Draw title
    LCD_DrawString_Internal(10, 10, "Handwritten Digit:", LCD_COLOR_BLACK, LCD_COLOR_WHITE);
    
    // Draw digit scaled 4x
    for(int i = 0; i < 28; i++)
    {
        for(int j = 0; j < 28; j++)
        {
            uint8_t pixel = digit_data[i * 28 + j];
            LCD_Color_t color = pixel ? LCD_COLOR_BLACK : LCD_COLOR_WHITE;
            
            // Scale 4x
            for(int dy = 0; dy < 4; dy++)
            {
                for(int dx = 0; dx < 4; dx++)
                {
                    LCD_DrawPixel_Internal(start_x + j*4 + dx, start_y + i*4 + dy, color);
                }
            }
        }
    }
    
    /* USER CODE END LCD_DisplayDigit_Internal */
}

/**
  * @brief  Display test pattern (28x28 checkerboard scaled 4x)
  */
static void LCD_DisplayTestPattern_Internal(void)
{
    /* USER CODE BEGIN LCD_DisplayTestPattern_Internal */
    
    extern int UART_Printf(const char *fmt, ...);
    
    // Flash colors to verify FSMC is working
    UART_Printf("[DEBUG] Filling RED...\r\n");
    LCD_Clear_Internal(LCD_COLOR_RED);
    HAL_Delay(200);
    
    UART_Printf("[DEBUG] Filling GREEN...\r\n");
    LCD_Clear_Internal(LCD_COLOR_GREEN);
    HAL_Delay(200);
    
    UART_Printf("[DEBUG] Filling BLUE...\r\n");
    LCD_Clear_Internal(LCD_COLOR_BLUE);
    HAL_Delay(200);
    
    UART_Printf("[DEBUG] Filling WHITE...\r\n");
    LCD_Clear_Internal(LCD_COLOR_WHITE);
    HAL_Delay(200);
    
    uint16_t start_x = (LCD_WIDTH - 28*4) / 2;   // Center horizontally (scale 4x)
    uint16_t start_y = (LCD_HEIGHT - 28*4) / 2;  // Center vertically (scale 4x)
    
    // Clear screen with gray background
    UART_Printf("[DEBUG] Drawing gray background...\r\n");
    LCD_Clear_Internal(LCD_COLOR_GRAY);
    
    // Draw title
    UART_Printf("[DEBUG] Drawing text...\r\n");
    LCD_DrawString_Internal(10, 10, "LCD Test Pattern", LCD_COLOR_WHITE, LCD_COLOR_GRAY);
    LCD_DrawString_Internal(10, 25, "28x28 Checkerboard", LCD_COLOR_WHITE, LCD_COLOR_GRAY);
    
    // Draw 28x28 checkerboard scaled 4x
    UART_Printf("[DEBUG] Drawing checkerboard pattern...\r\n");
    for(int i = 0; i < 28; i++)
    {
        for(int j = 0; j < 28; j++)
        {
            // Checkerboard pattern: alternate black and white
            LCD_Color_t color = ((i + j) % 2 == 0) ? LCD_COLOR_BLACK : LCD_COLOR_WHITE;
            
            // Scale 4x - draw 4x4 block for each cell
            for(int dy = 0; dy < 4; dy++)
            {
                for(int dx = 0; dx < 4; dx++)
                {
                    LCD_DrawPixel_Internal(start_x + j*4 + dx, start_y + i*4 + dy, color);
                }
            }
        }
    }
    
    // Draw border around pattern
    for(int i = 0; i < 28*4; i++)
    {
        // Top border
        LCD_DrawPixel_Internal(start_x + i, start_y - 1, LCD_COLOR_RED);
        // Bottom border
        LCD_DrawPixel_Internal(start_x + i, start_y + 28*4, LCD_COLOR_RED);
        // Left border
        LCD_DrawPixel_Internal(start_x - 1, start_y + i, LCD_COLOR_RED);
        // Right border
        LCD_DrawPixel_Internal(start_x + 28*4, start_y + i, LCD_COLOR_RED);
    }
    
    // Draw info text at bottom
    UART_Printf("[DEBUG] Drawing footer text...\r\n");
    LCD_DrawString_Internal(10, LCD_HEIGHT - 30, "All pixels OK?", LCD_COLOR_YELLOW, LCD_COLOR_GRAY);
    LCD_DrawString_Internal(10, LCD_HEIGHT - 15, "Ready for data", LCD_COLOR_GREEN, LCD_COLOR_GRAY);
    
    UART_Printf("[DEBUG] Test pattern complete!\r\n");
    
    /* USER CODE END LCD_DisplayTestPattern_Internal */
}

/* Public function wrappers */
void LCD_Init(void)
{
    LCD_Init_Internal();
}

void LCD_FillColor(uint16_t x, uint16_t y, uint16_t w, uint16_t h, LCD_Color_t color)
{
    LCD_FillColor_Internal(x, y, w, h, color);
}

void LCD_DrawPixel(uint16_t x, uint16_t y, LCD_Color_t color)
{
    LCD_DrawPixel_Internal(x, y, color);
}

void LCD_DrawChar(uint16_t x, uint16_t y, char c, LCD_Color_t fg, LCD_Color_t bg)
{
    LCD_DrawChar_Internal(x, y, c, fg, bg);
}

void LCD_DrawString(uint16_t x, uint16_t y, const char *str, LCD_Color_t fg, LCD_Color_t bg)
{
    LCD_DrawString_Internal(x, y, str, fg, bg);
}

void LCD_Clear(LCD_Color_t color)
{
    LCD_Clear_Internal(color);
}

void LCD_DisplayDigit(const uint8_t *digit_data)
{
    LCD_DisplayDigit_Internal(digit_data);
}

void LCD_DisplayTestPattern(void)
{
    LCD_DisplayTestPattern_Internal();
}

/********************************************************
  End Of File
********************************************************/
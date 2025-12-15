/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : seg7.c
  * @brief          : 7-segment display driver implementation
  *                   Using 74HC595 and 74HC138
  ******************************************************************************
  */
/* USER CODE END Header */

#include "seg7.h"

/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Private variables */
static uint8_t seg7_buffer[SEG7_NUM_DIGITS];
static uint8_t current_digit = 0;

/* 7-segment display encoding (common cathode)
   Segment map: DP G F E D C B A
   Bit:         7  6 5 4 3 2 1 0
*/
static const uint8_t seg7_table[16] = {
    0x3F, // 0: 0b00111111
    0x06, // 1: 0b00000110
    0x5B, // 2: 0b01011011
    0x4F, // 3: 0b01001111
    0x66, // 4: 0b01100110
    0x6D, // 5: 0b01101101
    0x7D, // 6: 0b01111101
    0x07, // 7: 0b00000111
    0x7F, // 8: 0b01111111
    0x6F, // 9: 0b01101111
    0x77, // A: 0b01110111
    0x7C, // b: 0b01111100
    0x39, // C: 0b00111001
    0x5E, // d: 0b01011110
    0x79, // E: 0b01111001
    0x71  // F: 0b01110001
};

/* USER CODE BEGIN PV */

/* USER CODE END PV */

/**
  * @brief  Send byte to 74HC595
  * @param  data: byte to send
  */
static void SEG7_SendByte(uint8_t data)
{
    /* USER CODE BEGIN SEG7_SendByte */
    
    for(int i = 0; i < 8; i++)
    {
        SEG7_SCK_LOW;
        
        if(data & 0x80)
        {
            SEG7_SI_HIGH;
        }
        else
        {
            SEG7_SI_LOW;
        }
        
        data <<= 1;
        
        SEG7_SCK_HIGH;
    }
    
    SEG7_SCK_LOW;
    
    /* USER CODE END SEG7_SendByte */
}

/**
  * @brief  Latch data to 74HC595 output
  */
static void SEG7_Latch(void)
{
    /* USER CODE BEGIN SEG7_Latch */
    
    SEG7_RCK_LOW;
    SEG7_RCK_HIGH;
    SEG7_RCK_LOW;
    
    /* USER CODE END SEG7_Latch */
}

/**
  * @brief  Select digit using 74HC138
  * @param  digit: digit position (0-7)
  */
static void SEG7_SelectDigit(uint8_t digit)
{
    /* USER CODE BEGIN SEG7_SelectDigit */
    
    if(digit >= SEG7_NUM_DIGITS) return;
    
    // Set ABC pins for 74HC138
    HAL_GPIO_WritePin(SEG7_A_PORT, SEG7_A_PIN, (digit & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
    HAL_GPIO_WritePin(SEG7_B_PORT, SEG7_B_PIN, (digit & 0x02) ? GPIO_PIN_SET : GPIO_PIN_RESET);
    HAL_GPIO_WritePin(SEG7_C_PORT, SEG7_C_PIN, (digit & 0x04) ? GPIO_PIN_SET : GPIO_PIN_RESET);
    
    /* USER CODE END SEG7_SelectDigit */
}

/**
  * @brief  Initialize 7-segment display
  */
void SEG7_Init(void)
{
    /* USER CODE BEGIN SEG7_Init */
    
    // Clear buffer
    for(int i = 0; i < SEG7_NUM_DIGITS; i++)
    {
        seg7_buffer[i] = 0x00;
    }
    
    current_digit = 0;
    
    // Initialize pins
    SEG7_SI_LOW;
    SEG7_RCK_LOW;
    SEG7_SCK_LOW;
    
    // Clear all displays
    SEG7_Clear();
    
    /* USER CODE END SEG7_Init */
}

/**
  * @brief  Write value to specific digit
  * @param  digit: digit position (0-7)
  * @param  value: value to display (0-15)
  */
void SEG7_WriteDigit(uint8_t digit, uint8_t value)
{
    /* USER CODE BEGIN SEG7_WriteDigit */
    
    if(digit >= SEG7_NUM_DIGITS || value > 15) return;
    
    seg7_buffer[digit] = seg7_table[value];
    
    /* USER CODE END SEG7_WriteDigit */
}

/**
  * @brief  Set digit with raw segment code
  * @param  digit: digit position (0-7)
  * @param  seg_code: raw segment code
  */
void SEG7_SetDigit(uint8_t digit, uint8_t seg_code)
{
    /* USER CODE BEGIN SEG7_SetDigit */
    
    if(digit >= SEG7_NUM_DIGITS) return;
    
    seg7_buffer[digit] = seg_code;
    
    /* USER CODE END SEG7_SetDigit */
}

/**
  * @brief  Display a number
  * @param  number: number to display
  */
void SEG7_DisplayNumber(uint32_t number)
{
    /* USER CODE BEGIN SEG7_DisplayNumber */
    
    // Clear all digits first
    for(int i = 0; i < SEG7_NUM_DIGITS; i++)
    {
        seg7_buffer[i] = 0x00;
    }
    
    // Extract digits (rightmost digit is position 0)
    for(int i = 0; i < SEG7_NUM_DIGITS; i++)
    {
        seg7_buffer[i] = seg7_table[number % 10];
        number /= 10;
        if(number == 0) break;
    }
    
    /* USER CODE END SEG7_DisplayNumber */
}

/**
  * @brief  Clear all digits
  */
void SEG7_Clear(void)
{
    /* USER CODE BEGIN SEG7_Clear */
    
    for(int i = 0; i < SEG7_NUM_DIGITS; i++)
    {
        seg7_buffer[i] = 0x00;
        SEG7_SelectDigit(i);
        SEG7_SendByte(0x00);
        SEG7_Latch();
    }
    
    /* USER CODE END SEG7_Clear */
}

/**
  * @brief  Turn on all segments (display 8)
  */
void SEG7_AllOn(void)
{
    /* USER CODE BEGIN SEG7_AllOn */
    
    for(int i = 0; i < SEG7_NUM_DIGITS; i++)
    {
        seg7_buffer[i] = 0x7F; // All segments on
    }
    
    /* USER CODE END SEG7_AllOn */
}

/**
  * @brief  Refresh display (called periodically)
  */
void SEG7_Refresh(void)
{
    /* USER CODE BEGIN SEG7_Refresh */
    
    // Select current digit
    SEG7_SelectDigit(current_digit);
    
    // Send segment data
    SEG7_SendByte(seg7_buffer[current_digit]);
    
    // Latch data
    SEG7_Latch();
    
    // Move to next digit
    current_digit++;
    if(current_digit >= SEG7_NUM_DIGITS)
    {
        current_digit = 0;
    }
    
    /* USER CODE END SEG7_Refresh */
}

/**
  * @brief  Set buffer value
  * @param  digit: digit position (0-7)
  * @param  value: value to display (0-15)
  */
void SEG7_SetBuffer(uint8_t digit, uint8_t value)
{
    /* USER CODE BEGIN SEG7_SetBuffer */
    
    if(digit >= SEG7_NUM_DIGITS || value > 15) return;
    
    seg7_buffer[digit] = seg7_table[value];
    
    /* USER CODE END SEG7_SetBuffer */
}

/********************************************************
  End Of File
********************************************************/
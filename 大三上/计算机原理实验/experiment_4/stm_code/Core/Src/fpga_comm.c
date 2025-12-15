/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : fpga_comm.c
  * @brief          : FPGA communication driver implementation
  *                   For handwriting recognition with serial data transmission
  ******************************************************************************
  */
/* USER CODE END Header */

#include "fpga_comm.h"
#include <string.h>

/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Private variables */
static uint8_t fpga_data_buffer[FPGA_DATA_SIZE];
static uint16_t fpga_data_index = 0;
static FPGA_State_t fpga_state = FPGA_STATE_IDLE;
static uint8_t fpga_result = 0;
static bool clock_running = false;
static uint32_t clock_tick_counter = 0;

/* USER CODE BEGIN PV */

/* USER CODE END PV */

/**
  * @brief  Initialize FPGA interface
  */
void FPGA_Init(void)
{
    /* USER CODE BEGIN FPGA_Init */
    
    // Initialize control pins
    FPGA_CLK_LOW;
    FPGA_DATA_IN_LOW;
    FPGA_RST_LOW;
    
    // Clear data buffer
    memset(fpga_data_buffer, 0, FPGA_DATA_SIZE);
    
    // Reset state
    fpga_state = FPGA_STATE_IDLE;
    fpga_data_index = 0;
    fpga_result = 0;
    
    // Reset FPGA
    FPGA_Reset();
    
    /* USER CODE END FPGA_Init */
}

/**
  * @brief  Reset FPGA
  */
void FPGA_Reset(void)
{
    /* USER CODE BEGIN FPGA_Reset */
    
    extern void UART_Printf(const char *format, ...);
    volatile uint32_t delay;
    
    UART_Printf("[FPGA] Resetting FPGA state machine (RST: HIGH -> LOW)...\r\n");
    
    // Reset sequence: Pull RST HIGH then LOW to reset state machine
    FPGA_RST_HIGH;
    for(delay = 0; delay < 168000; delay++);  // ~10ms at 168MHz
    FPGA_RST_LOW;
    for(delay = 0; delay < 16800; delay++);   // ~1ms at 168MHz
    
    fpga_state = FPGA_STATE_IDLE;
    fpga_data_index = 0;
    
    UART_Printf("[FPGA] Reset complete, state machine ready.\r\n");
    
    /* USER CODE END FPGA_Reset */
}

/**
  * @brief  Start sending data to FPGA
  * @param  data: pointer to data buffer
  * @param  len: length of data
  */
void FPGA_StartSend(const uint8_t *data, uint16_t len)
{
    /* USER CODE BEGIN FPGA_StartSend */
    
    extern void UART_Printf(const char *format, ...);
    
    if(data == NULL || len > FPGA_DATA_SIZE) return;
    
    // Copy data to buffer
    memcpy(fpga_data_buffer, data, len);
    
    // Reset FPGA
    FPGA_Reset();
    
    // Initialize state
    fpga_state = FPGA_STATE_IDLE;
    fpga_data_index = 0;
    clock_running = true;
    clock_tick_counter = 0;
    
    UART_Printf("[FPGA] Clock started, waiting for BUSY signal...\r\n");
    
    /* USER CODE END FPGA_StartSend */
}

/**
  * @brief  Clock tick for FPGA (called by timer at 500Hz)
  *         This function sends one bit per call
  */
void FPGA_ClockTick(void)
{
    /* USER CODE BEGIN FPGA_ClockTick */
    
    extern void UART_Printf(const char *format, ...);
    
    // Only run if clock is enabled
    if(!clock_running)
    {
        FPGA_CLK_LOW;
        return;
    }
    
    // Increment tick counter
    clock_tick_counter++;
    
    // Print status every 500 ticks (1 second at 500Hz)
    if(clock_tick_counter % 500 == 0)
    {
        UART_Printf("[FPGA_CLK] Tick %lu, State: %s, Index: %d/784\r\n", 
                    clock_tick_counter, FPGA_GetStateName(fpga_state), fpga_data_index);
        FPGA_PrintIOStatus();
    }
    
    // State machine for data transmission
    if(fpga_state == FPGA_STATE_SENDING)
    {
        // Sending data - data changes on clock low, sampled on clock rising edge
        if(fpga_data_index < FPGA_DATA_SIZE)
        {
            // Set data bit (while clock is low)
            if(fpga_data_buffer[fpga_data_index])
            {
                FPGA_DATA_IN_HIGH;
            }
            else
            {
                FPGA_DATA_IN_LOW;
            }
            
            // Generate clock rising edge (data is sampled here)
            FPGA_CLK_HIGH;
            
            fpga_data_index++;
            
            // Check if all data sent
            if(fpga_data_index >= FPGA_DATA_SIZE)
            {
                UART_Printf("[FPGA_CLK] All 784 bits sent, switching to COMPUTING state\r\n");
                fpga_state = FPGA_STATE_COMPUTING;
            }
        }
        else
        {
            // Just toggle clock after data is sent
            FPGA_CLK_HIGH;
        }
    }
    else
    {
        // IDLE or COMPUTING state - just toggle clock
        FPGA_CLK_HIGH;
    }
    
    // Clock goes low on next tick (creates 50% duty cycle)
    FPGA_CLK_LOW;
    
    /* USER CODE END FPGA_ClockTick */
}

/**
  * @brief  Read result from FPGA
  * @retval Recognition result (0-9)
  */
uint8_t FPGA_ReadResult(void)
{
    /* USER CODE BEGIN FPGA_ReadResult */
    
    extern void UART_Printf(const char *format, ...);
    
    if(FPGA_IS_RESULT_VALID)
    {
        // Read 4-bit result from PC4-PC7
        uint32_t port_value = FPGA_DATA_OUT_PORT->IDR;
        fpga_result = (port_value >> 4) & 0x0F;
        fpga_state = FPGA_STATE_DONE;
        
        // Stop clock
        clock_running = false;
        FPGA_CLK_LOW;
        
        UART_Printf("[FPGA] Clock stopped, result read: %d\r\n", fpga_result);
        
        return fpga_result;
    }
    
    return fpga_result;
    
    /* USER CODE END FPGA_ReadResult */
}

/**
  * @brief  Get current FPGA state
  * @retval Current state
  */
FPGA_State_t FPGA_GetState(void)
{
    /* USER CODE BEGIN FPGA_GetState */
    
    return fpga_state;
    
    /* USER CODE END FPGA_GetState */
}

/**
  * @brief  Set FPGA state
  * @param  state: New state
  */
void FPGA_SetState(FPGA_State_t state)
{
    /* USER CODE BEGIN FPGA_SetState */
    
    extern void UART_Printf(const char *format, ...);
    
    UART_Printf("[FPGA] State changed: %s -> %s\r\n", 
                FPGA_GetStateName(fpga_state), FPGA_GetStateName(state));
    
    fpga_state = state;
    
    /* USER CODE END FPGA_SetState */
}

/**
  * @brief  Check if FPGA is busy
  * @retval true if busy, false otherwise
  */
bool FPGA_IsBusy(void)
{
    /* USER CODE BEGIN FPGA_IsBusy */
    
    return FPGA_IS_BUSY;
    
    /* USER CODE END FPGA_IsBusy */
}

/**
  * @brief  Check if result is valid
  * @retval true if valid, false otherwise
  */
bool FPGA_IsResultValid(void)
{
    /* USER CODE BEGIN FPGA_IsResultValid */
    
    return FPGA_IS_RESULT_VALID;
    
    /* USER CODE END FPGA_IsResultValid */
}

/**
  * @brief  Set data buffer
  * @param  data: pointer to data buffer (784 bytes)
  */
void FPGA_SetData(const uint8_t *data)
{
    /* USER CODE BEGIN FPGA_SetData */
    
    if(data != NULL)
    {
        memcpy(fpga_data_buffer, data, FPGA_DATA_SIZE);
    }
    
    // Reset state
    fpga_data_index = 0;
    fpga_state = FPGA_STATE_IDLE;
    clock_running = false;
    clock_tick_counter = 0;
    
    /* USER CODE END FPGA_SetData */
}

/**
  * @brief  Get data buffer pointer
  * @retval Pointer to data buffer
  */
const uint8_t* FPGA_GetData(void)
{
    /* USER CODE BEGIN FPGA_GetData */
    
    return fpga_data_buffer;
    
    /* USER CODE END FPGA_GetData */
}

/**
  * @brief  Get FPGA state name as string
  * @param  state: FPGA state
  * @retval State name string
  */
const char* FPGA_GetStateName(FPGA_State_t state)
{
    /* USER CODE BEGIN FPGA_GetStateName */
    
    switch(state)
    {
        case FPGA_STATE_IDLE:       return "IDLE";
        case FPGA_STATE_SENDING:    return "SENDING";
        case FPGA_STATE_COMPUTING:  return "COMPUTING";
        case FPGA_STATE_DONE:       return "DONE";
        default:                    return "UNKNOWN";
    }
    
    /* USER CODE END FPGA_GetStateName */
}

/**
  * @brief  Print FPGA IO status (brief)
  */
void FPGA_PrintIOStatus(void)
{
    /* USER CODE BEGIN FPGA_PrintIOStatus */
    
    extern void UART_Printf(const char *format, ...);
    
    // Read control pins
    GPIO_PinState rst_pin = HAL_GPIO_ReadPin(FPGA_RST_PORT, FPGA_RST_PIN);
    GPIO_PinState data_in_pin = HAL_GPIO_ReadPin(FPGA_DATA_IN_PORT, FPGA_DATA_IN_PIN);
    GPIO_PinState clk_pin = HAL_GPIO_ReadPin(FPGA_CLK_PORT, FPGA_CLK_PIN);
    
    // Read status pins
    GPIO_PinState busy_pin = HAL_GPIO_ReadPin(FPGA_BUSY_PORT, FPGA_BUSY_PIN);
    GPIO_PinState valid_pin = HAL_GPIO_ReadPin(FPGA_RESULT_VALID_PORT, FPGA_RESULT_VALID_PIN);
    
    // Read data output (PC4-PC7)
    uint32_t port_value = FPGA_DATA_OUT_PORT->IDR;
    uint8_t data_out = (port_value >> 4) & 0x0F;
    
    UART_Printf("[FPGA IO] RST=%d DATA_IN=%d CLK=%d | BUSY=%d VALID=%d OUT=0x%X\r\n",
                rst_pin, data_in_pin, clk_pin, busy_pin, valid_pin, data_out);
    
    /* USER CODE END FPGA_PrintIOStatus */
}

/**
  * @brief  Print detailed FPGA status
  */
void FPGA_PrintDetailedStatus(void)
{
    /* USER CODE BEGIN FPGA_PrintDetailedStatus */
    
    extern void UART_Printf(const char *format, ...);
    
    UART_Printf("\r\n");
    UART_Printf("=== FPGA Detailed Status ===\r\n");
    
    // State information
    UART_Printf("[State] Current: %s\r\n", FPGA_GetStateName(fpga_state));
    UART_Printf("[State] Data Index: %d / %d\r\n", fpga_data_index, FPGA_DATA_SIZE);
    UART_Printf("[State] Result: %d\r\n", fpga_result);
    
    // Control pins (PC0-PC2) - Output from STM32
    UART_Printf("\r\n[Control Pins - STM32 Output]\r\n");
    GPIO_PinState rst_pin = HAL_GPIO_ReadPin(FPGA_RST_PORT, FPGA_RST_PIN);
    GPIO_PinState data_in_pin = HAL_GPIO_ReadPin(FPGA_DATA_IN_PORT, FPGA_DATA_IN_PIN);
    GPIO_PinState clk_pin = HAL_GPIO_ReadPin(FPGA_CLK_PORT, FPGA_CLK_PIN);
    
    UART_Printf("  PC0 (RST):     %s\r\n", rst_pin ? "HIGH" : "LOW");
    UART_Printf("  PC1 (DATA_IN): %s\r\n", data_in_pin ? "HIGH" : "LOW");
    UART_Printf("  PC2 (CLK):     %s\r\n", clk_pin ? "HIGH" : "LOW");
    
    // Status pins (PC3, PC8) - Input to STM32
    UART_Printf("\r\n[Status Pins - FPGA Output]\r\n");
    GPIO_PinState busy_pin = HAL_GPIO_ReadPin(FPGA_BUSY_PORT, FPGA_BUSY_PIN);
    GPIO_PinState valid_pin = HAL_GPIO_ReadPin(FPGA_RESULT_VALID_PORT, FPGA_RESULT_VALID_PIN);
    
    UART_Printf("  PC3 (RESULT_VALID): %s\r\n", valid_pin ? "HIGH (Valid)" : "LOW (Not Valid)");
    UART_Printf("  PC8 (BUSY):         %s\r\n", busy_pin ? "HIGH (Busy)" : "LOW (Idle)");
    
    // Data output pins (PC4-PC7) - Input to STM32
    UART_Printf("\r\n[Data Output - FPGA Result]\r\n");
    uint32_t port_value = FPGA_DATA_OUT_PORT->IDR;
    uint8_t data_out = (port_value >> 4) & 0x0F;
    
    UART_Printf("  PC4-PC7: 0x%X (Binary: ", data_out);
    for(int i = 3; i >= 0; i--)
    {
        UART_Printf("%d", (data_out >> i) & 0x01);
    }
    UART_Printf(", Decimal: %d)\r\n", data_out);
    
    // Pin details
    UART_Printf("\r\n[Pin Mapping]\r\n");
    UART_Printf("  PC0: FPGA_RST        (Output)\r\n");
    UART_Printf("  PC1: FPGA_DATA_IN    (Output - Serial Data)\r\n");
    UART_Printf("  PC2: FPGA_CLK        (Output - 500Hz)\r\n");
    UART_Printf("  PC3: RESULT_VALID    (Input)\r\n");
    UART_Printf("  PC4: DATA_OUT[0]     (Input - LSB)\r\n");
    UART_Printf("  PC5: DATA_OUT[1]     (Input)\r\n");
    UART_Printf("  PC6: DATA_OUT[2]     (Input)\r\n");
    UART_Printf("  PC7: DATA_OUT[3]     (Input - MSB)\r\n");
    UART_Printf("  PC8: BUSY            (Input)\r\n");
    
    // Data buffer preview (first 28 pixels)
    UART_Printf("\r\n[Data Buffer Preview - First Row]\r\n");
    UART_Printf("  ");
    for(int i = 0; i < 28 && i < FPGA_DATA_SIZE; i++)
    {
        UART_Printf("%d", fpga_data_buffer[i]);
    }
    UART_Printf("\r\n");
    
    UART_Printf("============================\r\n\r\n");
    
    /* USER CODE END FPGA_PrintDetailedStatus */
}

/********************************************************
  End Of File
********************************************************/
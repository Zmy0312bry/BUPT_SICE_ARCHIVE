/*
 * @Author: zhao-leo 18055219130@163.com
 * @Date: 2024-10-06 00:12:00
 * @LastEditors: zhao-leo 18055219130@163.com
 * @LastEditTime: 2024-10-18 21:42:11
 * @FilePath: \module\password_box\password_box.v
 * @Description: 
 * 本密码箱包括以下功能：
 * 1. 输入密码 (支持最高9位纯数字密码，共387,420,489种可能)
 * 2. 修改密码 (支持修改密码)
 * 3. 锁定状态 (3次错误后锁定)
 * 5. 7段数码管显示(当前位数和当前输入)
 * 6. RGB LED状态显示（三色LED显示当前保险箱状态）
 * 
 * 本保险箱的安全性如下：
 * 1. 3次错误后的锁定状态可以有效防止暴力破解
 * 2. 9位纯数字密码的组合数较大，难以暴力破解
 * 3. 本密码箱支持修改密码，可以定期更换密码，增加安全性
 */
module password_box (
    input wire clk,                // 12MHz 时钟
    input reset,                   // 重置
    input wire modify_raw,             // 修改密码
    input wire input_digit_raw,        // 输入当前数字
    input wire input_password_raw,     // 输入密码
    input wire [3:0] switch,       // 4位开关输入
    output reg [7:0] seg1,         // 7段显示器显示 #1
    output reg [7:0] seg2,         // 7段显示器显示 #2
    output reg [2:0] led1_status,  // RGB LED1 状态 //(R,G,B)   // G15,E15,E14
    output reg [2:0] led2_status,  // RGB LED2 状态 //(R,G,B)   // C15,C14,D12
    output reg [2:0] red_led,      // 3个红色 LED               // N15,N14,M14
    output reg warning_led,        // 警告灯                    // K11
    output reg button_led
);
//去抖动模块
    wire modify;              // 按键 2 消抖脉冲
    wire input_digit;         // 按键 3 消抖脉冲
    wire input_password;      // 按键 4 消抖脉冲
    
    debounce module_x (
        .clk(clk),
        .rst(reset),
        .key({modify_raw, input_digit_raw, input_password_raw}),
        .key_pulse({modify, input_digit, input_password})
    );
//函数定义区域

    // 参数定义
    parameter MAX_ATTEMPTS = 3;                // 最大尝试次数

    // 最高位为位选信号，为0时允许七段数码管工作
    parameter ONE = 8'b0000_0110;
    parameter TWO = 8'b0101_1011;
    parameter THREE = 8'b0100_1111;
    parameter FOUR = 8'b0110_0110;
    parameter FIVE = 8'b0110_1101;
    parameter SIX = 8'b0111_1101;
    parameter SEVEN = 8'b0000_0111;
    parameter EIGHT = 8'b0111_1111;
    parameter NINE = 8'b0110_1111;
    parameter ZERO = 8'b0011_1111;
    parameter LINE =8'b0000_0000;

    // 状态定义（有限状态机）
    parameter IDLE = 3'b000;              // 空闲状态
    parameter INPUT_PASSWORD = 3'b001;    // 输入密码
    parameter CHECK_PASSWORD = 3'b010;    // 检查密码
    parameter MODIFY_PASSWORD = 3'b011;   // 修改密码
    parameter LOCKED = 3'b101;            // 锁定状态

    // 寄存器定义
    reg [2:0] current_state, next_state; // 状态机
    reg [23:0] entered_password;         // 输入密码缓冲区
    reg [1:0] attempts;                  // 尝试次数 0~3
    reg [3:0] password [0:8];
    reg [3:0] current_password_length;   // 当前密码长度
    reg [3:0] current_pwd [0:8];         // 正确密码

    // 寄存器初始化
    initial begin
        password[0] = 4'b0000;
        password[1] = 4'b0000;
        password[2] = 4'b0000;
        password[3] = 4'b0000;
        password[4] = 4'b0000;
        password[5] = 4'b0000;
        password[6] = 4'b0000;
        password[7] = 4'b0000;
        password[8] = 4'b0000;
        current_pwd[0] = 4'b0000;
        current_pwd[1] = 4'b0000;
        current_pwd[2] = 4'b0000;
        current_pwd[3] = 4'b0000;
        current_pwd[4] = 4'b0000;
        current_pwd[5] = 4'b0000;
        current_pwd[6] = 4'b0000;
        current_pwd[7] = 4'b0000;
        current_pwd[8] = 4'b0000;
    end

//函数定义区域
    // 7段数码管解码器
    function reg [7:0] decode_digit;
        input wire [3:0] digit;
        begin
            case (digit)
                4'b0000: decode_digit = ZERO; // 00
                4'b0001: decode_digit = ONE; // 01
                4'b0010: decode_digit = TWO; // 02
                4'b0011: decode_digit = THREE; // 03
                4'b0100: decode_digit = FOUR; // 04
                4'b0101: decode_digit = FIVE; // 05
                4'b0110: decode_digit = SIX; // 06
                4'b0111: decode_digit = SEVEN; // 07
                4'b1000: decode_digit = EIGHT; // 08
                4'b1001: decode_digit = NINE; // 09
                default: decode_digit = LINE; // 默认情况
            endcase
        end
    endfunction

    // attempt转led亮灯
    function reg [2:0] attempt_to_led;
        input reg [1:0] attempt;
        begin
            case (attempt)
                2'b00: attempt_to_led = 3'b111; // 3个红色
                2'b01: attempt_to_led = 3'b110; // 2个红色
                2'b10: attempt_to_led = 3'b100; // 1个红色
                2'b11: attempt_to_led = 3'b000; // 无红色
                default: attempt_to_led = 3'b000; // 默认情况
            endcase
        end
    endfunction

//Main区域
    always @(posedge clk) begin
        if (!reset) begin
            password[0] <= 4'b0000;
            password[1] <= 4'b0000;
            password[2] <= 4'b0000;
            password[3] <= 4'b0000;
            password[4] <= 4'b0000;
            password[5] <= 4'b0000;
            password[6] <= 4'b0000;
            password[7] <= 4'b0000;
            password[8] <= 4'b0000;
            current_password_length <= 0;
            attempts <= MAX_ATTEMPTS;
            next_state <= IDLE;
            led1_status <= 3'b011;
            led2_status <= 3'b101;
            button_led <= 0;
        end else begin
            case (current_state)
            IDLE: begin // 空闲状态
                red_led <= attempt_to_led(attempts); // 尝试次数转换为LED亮灯
                {seg1, seg2} = {LINE, LINE}; // 清空显示
                if (led1_status == 3'b101 && modify) begin
                    button_led <= ~button_led;
                    current_password_length <= 0;
                    next_state <= MODIFY_PASSWORD;
                end else if (led1_status == 3'b101 && input_password) begin
                    button_led <= ~button_led;
                    current_password_length <= 0;
                    led1_status <= 3'b011;
                    next_state <= IDLE;
                end else if (input_password) begin
                    current_password_length <= 0;
                    button_led <= ~button_led;
                    next_state <= INPUT_PASSWORD;
                end else begin
                    next_state <= IDLE;
                end
            end

            INPUT_PASSWORD: begin // 输入密码状态
                led1_status <= 3'b110; // LED1 蓝色
                seg2 <= decode_digit(switch); // 显示当前输入
                seg1 <= decode_digit(current_password_length); // 显示当前密码长度
                
                if (input_digit) begin
                    button_led <= ~button_led;
                    current_pwd[current_password_length] <= switch;
                    current_password_length <= current_password_length + 1;
                    next_state <= INPUT_PASSWORD;
                end else if (input_password) begin
                    button_led <= ~button_led;
                    next_state <= CHECK_PASSWORD;
                end else begin
                    next_state <= INPUT_PASSWORD;
                end
            end

            CHECK_PASSWORD: begin
                if (password[0]==current_pwd[0] &&
                    password[1]==current_pwd[1] &&
                    password[2]==current_pwd[2] &&
                    password[3]==current_pwd[3] &&
                    password[4]==current_pwd[4] &&
                    password[5]==current_pwd[5] &&
                    password[6]==current_pwd[6] &&
                    password[7]==current_pwd[7] &&
                    password[8]==current_pwd[8] ) begin
                    next_state = IDLE;
                    attempts = MAX_ATTEMPTS;
                    led1_status = 3'b101; // LED1 绿色
                end else begin
                    attempts <= attempts - 1;
                    if (attempts == 0) begin
                        next_state <= LOCKED;
                        led1_status <= 3'b011; // LED1 红色
                    end else begin
                        led1_status <= 3'b011; // LED1 红色
                        next_state <= IDLE;
                    end
                end
            end

            MODIFY_PASSWORD: begin
                led2_status <= 3'b110; // LED2 蓝色
                seg2 <= decode_digit(switch); // 显示当前输入
                seg1 <= decode_digit(current_password_length); // 显示当前密码长度
                
                if (input_digit) begin
                    button_led <= ~button_led;
                    current_pwd[current_password_length] <= switch;
                    current_password_length <= current_password_length + 1;
                    next_state <= MODIFY_PASSWORD;
                end
                else if (modify) begin
                    button_led <= ~button_led;
                    led2_status <= 3'b101; // LED2 绿色
                    password[0] <= current_pwd[0];
                    password[1] <= current_pwd[1];
                    password[2] <= current_pwd[2];
                    password[3] <= current_pwd[3];
                    password[4] <= current_pwd[4];
                    password[5] <= current_pwd[5];
                    password[6] <= current_pwd[6];
                    password[7] <= current_pwd[7];
                    password[8] <= current_pwd[8];
                    next_state <= IDLE;
                end else begin
                    next_state <= MODIFY_PASSWORD;
                end
            end

            LOCKED: begin
                led1_status <= 3'b011; // LED1 红色
                led2_status <= 3'b011; // LED2 红色
                red_led <= attempt_to_led(attempts); // 尝试次数转换为LED亮灯
                warning_led <= ~warning_led;
                next_state <= LOCKED;
            end

            default: next_state <= IDLE; // 默认情况
        endcase
        end
    end
    always @(posedge clk) begin
        current_state <= next_state;
    end
endmodule

module debounce (clk,rst,key,key_pulse);
parameter N = 3; //要消除的按键的数量
 input clk;
 input rst;
 input [N-1:0] key; //输入的按键 
 output [N-1:0] key_pulse; //按键动作产生的脉冲
 reg [N-1:0] key_rst_pre; //存储上一个触发时的按键值
 reg [N-1:0] key_rst; //储存储当前时刻触发的按键值
 wire [N-1:0] key_edge; //按键由高到低变化时产生一个高脉冲
//利用非阻塞赋值特点，将两个时钟触发的按键状态存储在两个寄存器变量中
 always @(posedge clk or negedge rst) begin
 if (!rst) begin
 key_rst <= {N{1'b1}}; //初始化时给 key_rst 赋值全为 1
 key_rst_pre <= {N{1'b1}};
 end
 else begin
//第一个时钟上升沿将 key 的值赋给 key_rst,同时 key_rst 的值赋给 key_rst_pre
//非阻塞赋值，相当于经过两个时钟触发，key_rst 存储当前时刻 key 的值，key_rst_pre 存储前一个时钟的 key 的值
key_rst <= key; 
key_rst_pre <= key_rst; 
 end 
 end
 //脉冲边沿检测。当 key 检测到下降沿时，key_edge 产生一个时钟周期的高电平
 assign key_edge = key_rst_pre & (~key_rst);
 reg [17:0] cnt; //产生延时所用的计数器，系统时钟 12MHz 
 //产生 20ms 延时，当检测到 key_edge 有效是计数器清零开始计数
 always @(posedge clk or negedge rst) begin
 if(!rst)
 cnt <= 18'h0;
 else if(key_edge)
 cnt <= 18'h0;
 else
 cnt <= cnt + 1'h1;
 end 
 reg [N-1:0] key_sec_pre; //延时后检测电平寄存器变量
 reg [N-1:0] key_sec; 
 //延时后检测 key，如果按键状态变低则按键有效，产生一个时钟周期的高电平。
 always @(posedge clk or negedge rst) begin
 if (!rst)
 key_sec <= {N{1'b1}}; 
 else if (cnt==18'h3ffff)
 key_sec <= key; 
 end
 always @(posedge clk or negedge rst)begin
 if (!rst)
key_sec_pre <= {N{1'b1}};
 else 
 key_sec_pre <= key_sec; 
 end
 assign key_pulse = key_sec_pre & (~key_sec); 
endmodule
module debounce (
    input wire clk,             // 时钟信号
    input wire rst_n,           // 异步复位信号，低电平有效
    input wire key_in,          // 原始按键输入信号
    output reg key_pressed,     // 按键按下信号
    output reg key_released     // 按键释放信号
);

    // 参数定义：假设消抖时间为 20ms
    parameter DEBOUNCE_TIME = 20_000; // 假设时钟频率为 1 MHz（即 1us 一个周期）
    reg [19:0] debounce_cnt;         // 消抖计数器
    reg key_state;                   // 按键稳定状态
    reg key_state_last;              // 上一个稳定状态

    // 按键状态同步
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounce_cnt <= 20'd0;
            key_state <= 1'b0;       // 默认按键未按下（低电平为未按下）
            key_state_last <= 1'b0;
        end else begin
            if (key_in == key_state) begin
                // 输入信号和稳定状态一致，计数器清零
                debounce_cnt <= 20'd0;
            end else begin
                // 输入信号和稳定状态不一致，计数器累加
                if (debounce_cnt < DEBOUNCE_TIME) begin
                    debounce_cnt <= debounce_cnt + 20'd1;
                end else begin
                    // 当计数器满时，更新稳定状态
                    debounce_cnt <= 20'd0;
                    key_state <= key_in;
                end
            end
            // 保存上一个稳定状态
            key_state_last <= key_state;
        end
    end

    // 按键事件检测
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_pressed <= 1'b0;
            key_released <= 1'b0;
        end else begin
            key_pressed <= (key_state_last == 1'b0) && (key_state == 1'b1);  // 按键从未按下到按下
            key_released <= (key_state_last == 1'b1) && (key_state == 1'b0); // 按键从按下到未按下
        end
    end

endmodule

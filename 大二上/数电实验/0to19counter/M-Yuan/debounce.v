module debounce(
    input wire clk,            // 时钟信号 (100Hz)
    input wire button,         // 原始按键输入
    output reg btn_state       // 消抖后的按键状态
);

    reg [1:0] counter;         // 2 位计数器，用于稳定计数

    // 初始化计数器
    initial begin 
        counter = 2'b00;
        btn_state = 1'b0;
    end

    always @(posedge clk) begin
        if (button) begin
            // 如果按键被按下，开始计数
            if (counter == 2'b10) begin
                // 达到20ms延时，确认按键按下
                btn_state <= ~btn_state;
            end else begin
                counter <= counter + 1;
            end
    end
	 end

endmodule


module debounce2(
    input wire clk,            // 时钟信号 (100Hz)
    input wire button,         // 原始按键输入
    output reg btn_state       // 消抖后的按键状态
);

    reg [1:0] counter;         // 2 位计数器，用于稳定计数

    // 初始化计数器
    initial begin 
        counter = 2'b00;
        btn_state = 1'b0;
    end

    always @(posedge clk) begin
        if (button) begin
            // 如果按键被按下，开始计数
            if (counter == 2'b10) begin
                // 达到20ms延时，确认按键按下
                btn_state <= 1;
            end else begin
                counter <= counter + 1;
            end
        end else begin
            // 如果按键未被按下，清空计数器和状态
            counter <= 2'b00;
            btn_state <= 1'b0;
        end
    end

endmodule

			
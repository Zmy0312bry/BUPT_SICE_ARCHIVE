module debounce(
    input wire clk,               // 时钟信号 (100Hz)
    input wire input_btn,         // 原始按键输入
    output reg output_btn         // 消抖后的按键状态
);

    reg [1:0] counter;           // 2 位计数器，用于稳定计数

    // 初始化计数器
    initial begin 
        counter = 2'b00;
		  output_btn = 1'b0;
    end

    always @(posedge clk) begin
        if (input_btn) begin
            // 如果按键被按下，开始计数
            if (counter == 2'b11) begin
                // 达到稳定计数，确认按键按下
                if (input_btn) begin
						output_btn <= 1'b1;
					 end else begin
						output_btn <= 1'b0;
					 end
            end else begin
                counter <= counter + 1'b1;
            end
        end else begin
            // 如果按键未被按下，清空计数器和状态
            counter <= 2'b00;
            output_btn <= 1'b0;
        end
    end
endmodule

			
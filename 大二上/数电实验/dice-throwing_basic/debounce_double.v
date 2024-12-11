module debounce_double (     
    input stop,               //暂停时候不进行任何逻辑
	 input wire clk,           // 时钟信号
    input wire btn_in,        // 原始按键信号
    output reg btn_out        // 去抖动后的稳定按键信号
);
    reg [16:0] counter = 0;   // 用于计数的20位计数器
    reg btn_sync_0, btn_sync_1;  // 同步化寄存器
    reg btn_state = 0;        // 记录当前稳定的按键状态

	 // 使用两个触发器同步按键输入信号，避免亚稳态
    always @(posedge clk or posedge stop) begin
			  btn_sync_0 <= btn_in;           // 第一层同步
			  btn_sync_1 <= btn_sync_0;       // 第二层同步
    end

    // 计时器和去抖动逻辑
    always @(posedge clk or posedge stop) begin
       if(stop)begin
			btn_out<=0;
		 end
		 else begin
		  if (btn_sync_1 != btn_state) begin
            // 如果检测到按键状态发生变化，开始计时
            counter <= counter + 1;
            if (counter == 16'b0100_1110_0010_0000) begin  // 经过足够长时间（20位计数器达到最大）
                btn_state <= btn_sync_1;    // 更新按键状态
                btn_out <= btn_sync_1;      // 输出去抖动后的按键信号
                counter <= 0;               // 计数器清零
            end
        end else begin
            counter <= 0;  // 如果按键状态没有变化，计数器保持清零
        end
		 end
    end
endmodule
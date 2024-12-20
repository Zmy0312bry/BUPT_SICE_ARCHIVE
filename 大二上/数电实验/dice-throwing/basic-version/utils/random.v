module random(
	 input clk,
    input wire rst,          // 复位信号
    input wire roll,         // 掷骰子触发信号
    output reg [3:0] dice,    // 输出随机数（0-9）
	 input finish
);

    reg [3:0] lfsr;          // 4 位线性反馈移位寄存器 (LFSR)

initial begin
	lfsr <= 4'b1001;  // 初始化 LFSR，不为 0
   dice <= 4'b1001;
end

    always @(posedge roll or negedge rst or posedge finish) begin
        if (!rst) begin
            lfsr <= 4'b1001;  // 初始化 LFSR，不为 0
            dice <= 4'b1001;  // 初始骰子值为 0
        end else if (finish) begin
				dice<=4'b1001;
        end
		  else begin
				if(roll)begin
            // 更新 LFSR 值
            lfsr <= {lfsr[2:0], lfsr[3] ^ lfsr[2]};
            dice <= (lfsr % 9)+1;  // 映射到 0-9
				end
		  end
    end
endmodule


module random2(
	 input clk,
    input wire rst,          // 复位信号
    input wire roll,         // 掷骰子触发信号
    output reg [3:0] dice,    // 输出随机数（0-9）
	 input finish
);

    reg [3:0] lfsr;          // 4 位线性反馈移位寄存器 (LFSR)

initial begin
	lfsr <= 4'b0001;  // 初始化 LFSR，不为 0
   dice <= 4'b1001;
end	 

    always @(posedge roll or negedge rst or posedge finish) begin
        if (!rst) begin
            lfsr <= 4'b0001;  // 初始化 LFSR，不为 0
            dice <= 4'b1001;  // 初始骰子值为 0
        end else if (finish) begin
				dice<=4'b1001;
        end
		  else begin
				if(roll)begin
            // 更新 LFSR 值
            lfsr <= {lfsr[2:0], lfsr[3] ^ lfsr[2]};
            dice <= (lfsr % 9)+1;  // 映射到 0-9
				end
		  end
    end
endmodule



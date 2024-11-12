module div_100(
	input clk,  //100Hz时钟
	input rst,
	output reg div_clk  //1Hz时钟
);
	reg [6:0] cnt = 0; // 从0开始计数

	// 初始化div_clk
	initial begin
		div_clk = 0;
	end

	always @(posedge clk or posedge rst) begin
		if (rst) begin
		div_clk = 1;
		cnt = 49;
		end else if (cnt == 49) begin // 计数到99
			cnt = 0;
			div_clk = ~div_clk;
		end else begin
			cnt = cnt + 1;
		end
	end
endmodule

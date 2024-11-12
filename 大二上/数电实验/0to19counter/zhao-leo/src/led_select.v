module led_select( // 低电平有效
	input clk, // 100Hz时钟信号
	output reg [1:0] select
);
	initial begin
		select = 2'b10;
	end
	always @(negedge clk) begin
		select <= {select[0], select[1]};
	end
		
endmodule
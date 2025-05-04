module pwm(
	input clk,
	input rst_n,
	input [7:0] duty_cycle,
	input [7:0] offset, // max 255
	output reg pwm_out
);
	reg [7:0] cnt;
	initial begin
		cnt = offset % 256;
		pwm_out = 1'b0;
	end
	always@(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			cnt <= offset % 256;
			pwm_out <= 0;
		end else begin
			pwm_out = (cnt < duty_cycle) ? 1:0;
			cnt = cnt + 1;
		end
	end
endmodule
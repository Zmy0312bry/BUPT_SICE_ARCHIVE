module Colorful_led(
	output [2:0] rgb_led_1,
// output [2:0] rgb_led_2,
	input clk,
	input rst_n
);
	pwm_line pwm1(
	.clk(clk),
	.rst_n(rst_n),
	.offset_line(8'h00),
	.pwm_out(rgb_led_1[0])
	);

	pwm_line pwm2(
	.clk(clk),
	.rst_n(rst_n),
	.offset_line(8'h55),
	.pwm_out(rgb_led_1[1])
	);
	
	pwm_line pwm3(
	.clk(clk),
	.rst_n(rst_n),
	.offset_line(8'haa),
	.pwm_out(rgb_led_1[2])
	);
endmodule
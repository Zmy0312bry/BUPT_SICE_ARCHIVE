`timescale 1ms/1ps
module tb_colorful_led;
	reg clk;
	
	wire [2:0] led;
	
	initial begin
		clk = 0;
		forever #5 clk=~clk;
	end
	Colorful_led uut(
		.rgb_led_1(led),
	// output [2:0] rgb_led_2,
		.clk(clk),
		.rst_n(1'b1)
	);
	initial begin
	# 2100000000;
	$finish;
	end

	initial begin
		$dumpfile("tb_colorful_led.vcd");
		$dumpvars(0,tb_colorful_led);
	end
endmodule
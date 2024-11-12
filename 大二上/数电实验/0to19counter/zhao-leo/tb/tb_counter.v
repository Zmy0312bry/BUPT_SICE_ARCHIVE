`timescale 1ms / 1us
 
module counter_test;
	// 输入
	reg clk;
	initial begin
		clk = 0;
		forever #5 clk = ~clk; // 100Hz
	end
	initial begin   
		$dumpfile("tb_counter.vcd");   
		$dumpvars(0, counter_test);   
	end 
	reg btn = 0;
	reg rst = 0;
	
	wire [6:0] led_signal;
	wire [1:0] select_led;
	wire [5:0] other_led;
	
	counter uut(
		.btn(btn),
		.rst(rst),
		.clk(clk),
		.led_signal(led_signal),
		.select_led(select_led),
		.other_led(other_led)
	);
	
	initial begin
		#5600; //基本功能
		btn = 1;//按下暂停
		# 40;
		btn = 0;
		# 5000;

		btn = 1;//按下继续
		# 40;
		btn = 0;
		# 1000;
		
		# 10;
		btn = 1; //消抖
		# 10;
		btn = 0;
		# 5300;
		
		# 120;//验证异步复位按钮
		rst = 1;
		# 100;
		rst = 0;
		# 3000;
		$finish;
	
	end
	 
endmodule
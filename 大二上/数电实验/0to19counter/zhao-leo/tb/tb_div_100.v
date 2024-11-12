`timescale 1ms / 1ps

module div_100_test;

    // 输入
    reg clk;
	 reg rst;

    // 输出
    wire div_clk;

    // 实例化模块
    div_100 uut (
        .clk(clk), 
        .div_clk(div_clk),
		  .rst(rst)
    );
	initial begin   
		$dumpfile("tb_div_100.vcd");   
		$dumpvars(0, div_100_test);   
	end 
    // 时钟信号生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100Hz
    end

    // 测试主体
    initial begin
		  rst = 0;

        #3100;
		  rst = 1;
		  #2230;
		  rst = 0;
		  #5000;
        $finish;
    end

endmodule

`timescale 1ms / 1ps

module led_select_test;

    // 输入
    reg clk;

    // 输出
    wire [1:0] select;
	initial begin   
		$dumpfile("tb_led_select.vcd");   
		$dumpvars(0, led_select_test);   
	end 
    // 实例化模块
    led_select uut (
        .clk(clk), 
        .select(select)
    );

    // 时钟信号生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100Hz
    end

    // 测试主体
    initial begin

        #10000;
        // 结束仿真
        $finish;
    end

endmodule

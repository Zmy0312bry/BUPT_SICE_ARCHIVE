`timescale 1ms / 1ps

module debounce_test;

    // 输入
    reg clk;
    reg input_btn;

    // 输出
    wire output_btn;
	initial begin   
		$dumpfile("tb_debounce.vcd");   
		$dumpvars(0, debounce_test);   
	end 
    // 实例化模块
    debounce uut (
        .clk(clk), 
        .input_btn(input_btn), 
        .output_btn(output_btn)
    );

    // 时钟信号生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100Hz
    end

    // 测试主体
    initial begin
        input_btn = 0;

        #10;

        // 生成一些噪音
        #5 input_btn = 1; // 按下按钮
        #1 input_btn = 0;   // 噪音
        #1 input_btn = 1;   // 保持按下
        #1 input_btn = 0;   // 噪音
        #1 input_btn = 1;   // 保持按下
        #30 input_btn = 0; // 放手
        #20;

        // 结束仿真
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time: %t, input_btn: %b, output_btn: %b",$time, input_btn, output_btn);
    end

endmodule

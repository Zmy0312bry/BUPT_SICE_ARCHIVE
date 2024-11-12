`timescale 1ms / 1ms

module tb_counter;
    // 通过寄存器定义信号来模拟输入
    reg clk;          // 时钟信号
    reg [1:0] btn;    // 两个按键输入
    wire [7:0] seg;   // 数码管输出
    wire [1:0] cat;   // 位选信号
	 wire clk_1;
	 wire [1:0] btn_state;

	 assign clk_1=0;
    // 实例化待测试的模块
    counter uut (
        .clk(clk),
        .btn(btn),
        .seg(seg),
        .cat(cat)
		  
    );
	 

	 

    // 时钟生成器，周期为10ms，频率为100Hz
    always begin
        #10 clk = ~clk;  // 时钟信号周期为10ms，对应100Hz
    end

    // 初始化信号
    initial begin
        // 初始化
        clk = 0;
        btn = 2'b00;  // 初始时，按钮都未按下


        // 模拟按下暂停按钮两次，每次间隔 1 秒（1000 个时钟周期）
        #2500 btn = 2'b01;  // 按下暂停按钮
        #100 btn = 2'b00;  // 释放暂停按钮，等待 1 秒（1000 时钟周期）
        
        #1500 btn = 2'b01;  // 再次按下暂停按钮
        #100 btn = 2'b00;  // 释放暂停按钮，等待 1 秒（1000 时钟周期）

        // 测试计数值复位
        #2000 btn = 2'b10;  // 按下复位按钮
        #100 btn = 2'b00;  // 释放复位按钮

        // 结束仿真
        #20_000;          // 延长仿真时间到20秒
        $finish;
    end

    // 使用 $monitor 输出信号
    initial begin
        // 每次信号发生变化时，输出以下信息
        $monitor("Time = %0t | btn = %b | seg = %b | cat = %b | clk_1 = %b ", $time, btn, seg, cat,clk_1);
    end
endmodule


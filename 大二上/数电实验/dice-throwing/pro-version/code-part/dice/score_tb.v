`timescale 1ns/1ps

module score_tb;
    // 仿真信号声明
    reg clk, rst;
    reg start1, start2;
    reg [3:0] dice1, dice2;
    wire [3:0] state1, state2;
    wire times, is_final, finish;

    // 内部信号监控 (添加内部信号)
    wire [27:0] cnt;
    wire [3:0] difference,s_tmp1,s_tmp2;
    wire start1_sync, start2_sync, start1_before, start2_before, flag1, flag2, sign;

    // 实例化被测模块 (DUT: Device Under Test)
    score uut (
        .clk(clk),
        .rst(rst),
        .start1(start1),
        .start2(start2),
        .dice1(dice1),
        .dice2(dice2),
        .state1(state1),
        .state2(state2),
        .times(times),
        .is_final(is_final),
        .finish(finish)
    );

    // 信号绑定到内部变量 (从DUT中获取内部信号)
    assign cnt = uut.cnt;
    assign difference = uut.difference;
    assign sign = uut.sign;
	 assign s_tmp1 = uut.state1_tmp;
	 assign s_tmp2 = uut.state2_tmp;
	 assign state1 = uut.state1;
	 assign state2 = uut.state2;

    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 时钟周期为10ns
    end

    // 仿真逻辑
    initial begin
        // 初始化信号
        rst = 0;
        start1 = 0;
        start2 = 0;
        dice1 = 0;
        dice2 = 0;

        // 开始仿真
        #20 rst = 1; // 释放复位
        #10 dice1 = 4'd5; dice2 = 4'd3; // 投骰子，dice1 > dice2
        #10 start1 = 1; #10 start1 = 0; // 模拟按下并松开start1
        #10 start2 = 1; #10 start2 = 0; // 模拟按下并松开start2
		  #60 start1 = 1; #10 start1 = 0; // 模拟按下并松开start1
        #10 start2 = 1; #10 start2 = 0; // 模拟按下并松开start2

        #10000; // 等待计时

        #10 start1 = 1; #10 start1 = 0; // 新一轮按键
        #10 start2 = 1; #10 start2 = 0;
        #10 dice1 = 4'd2; dice2 = 4'd6; // 投骰子，dice1 < dice2
        #10000;

        // 测试平局
        #10 start1 = 1; #10 start1 = 0;
        #10 start2 = 1; #10 start2 = 0;
        #10 dice1 = 4'd4; dice2 = 4'd4; // 投骰子，平局
        #10000;
		  
		          // 测试平局
        #10 start1 = 1; #10 start1 = 0;
        #10 start2 = 1; #10 start2 = 0;
        #10 dice1 = 4'd2; dice2 = 4'd6; // 投骰子
        #10000;
		  
        // 测试平局
        #10 start1 = 1; #10 start1 = 0;
        #10 start2 = 1; #10 start2 = 0;
        #10 dice1 = 4'd2; dice2 = 4'd6; // 投骰子
        #10000;
        // 测试平局
        #10 start1 = 1; #10 start1 = 0;
        #10 start2 = 1; #10 start2 = 0;
        #10 dice1 = 4'd2; dice2 = 4'd6; // 投骰
        #10000;
        // 结束仿真
        #100 $stop;
    end

    // 打印内部信号以便实时监控
    initial begin
        $monitor("Time: %0t | start1_sync: %b | start2_sync: %b | flag1: %b | flag2: %b | sign: %b | cnt: %d | difference: %d | state1: %d | state2: %d | times: %b | is_final: %b | finish: %b",
                 $time, start1_sync, start2_sync, flag1, flag2, sign, cnt, difference, state1, state2, times, is_final, finish);
    end
endmodule

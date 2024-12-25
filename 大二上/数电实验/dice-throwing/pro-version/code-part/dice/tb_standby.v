`timescale 1ns / 1ps

module tb_standby;

    // 测试平台的信号声明
    reg clk;                   // 时钟信号
    reg rst;                   // 复位信号
    reg times;                 // 游戏时间信号
    reg is_final;              // 是否为最后一局信号
    reg is_finish;             // 游戏是否结束
    reg [3:0] score1, score2; // 玩家1和玩家2的分数
    wire [15:0] rgb_led;      // RGB灯光信号输出

    // 实例化 standby 模块
    standby uut (
        .clk(clk),
        .times(times),
        .is_final(is_final),
        .rst(rst),
        .score1(score1),
        .score2(score2),
        .rgb_led(rgb_led),
        .is_finish(is_finish)
    );

    // 时钟生成，每 5 ns 翻转时钟，模拟 100 MHz 时钟
    always begin
        #5 clk = ~clk;  
    end

    // 仿真初始化
    initial begin
        // 初始化信号
        clk = 0;
        rst = 1;
        times = 0;
        is_final = 0;
        is_finish = 0;
        score1 = 4'b0000;
        score2 = 4'b0000;

        // 打开仿真输出
        $monitor("At time %t: rgb_led = %b, score1 = %d, score2 = %d, is_final = %b", 
                 $time, rgb_led, score1, score2, is_final);

        // 仿真过程
        #10 score1 = 4'b0101; score2 = 4'b0011; times = 1; // 设置分数
        #1500 times = 0;
		  #500;
        is_final = 1; // 进入最后一局
		  times = 1;
        #50 score1 = 4'b0111; score2 = 4'b0100; // 更新分数
		  #1500 times=0;score2 = 4'b0111; score1 = 4'b0100;
        #10 times = 1; // 结束最后一局，恢复正常状态
		  #1500;
        #200 is_finish = 1;is_final=0;times=0; // 设置游戏结束
        #50 $finish; // 结束仿真
    end

endmodule

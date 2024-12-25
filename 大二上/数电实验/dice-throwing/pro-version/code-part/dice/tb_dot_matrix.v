`timescale 1ns / 1ps

module tb_dot_matrix;

    // 测试平台的信号声明
    reg clk;                    // 时钟信号
    reg rst;                    // 复位信号
    reg stop;                   // 停止信号
    reg [3:0] dice1, dice2;     // 骰子数字输入
    wire [7:0] row;             // 行信号输出
    wire [7:0] r_col;           // 红色列信号输出
    wire [7:0] g_col;           // 绿色列信号输出

    // 实例化 dot_matrix 模块
    dot_matrix uut (
        .clk(clk),
        .rst(rst),
        .stop(stop),
        .dice1(dice1),
        .dice2(dice2),
        .row(row),
        .r_col(r_col),
        .g_col(g_col)
    );

    // 时钟生成
    always begin
        #5 clk = ~clk;  // 每 5 ns 翻转时钟
    end

    // 仿真初始化
    initial begin
        // 初始化信号
        clk = 0;
        rst = 0;
        stop = 0;
        dice1 = 4'b0000;  // 默认骰子1为0
        dice2 = 4'b0000;  // 默认骰子2为0

        // 打开仿真输出
        $monitor("At time %t: row = %b, r_col = %b, g_col = %b, dice1 = %d, dice2 = %d", 
                 $time, row, r_col, g_col, dice1, dice2);

        // 仿真过程
        #10 rst = 1;  // 释放复位信号
        #10 dice1 = 4'b0001; dice2 = 4'b0010;  // 骰子1 = 1, 骰子2 = 2
        #50 dice1 = 4'b0011; dice2 = 4'b0101;  // 骰子1 = 3, 骰子2 = 5
        #50 dice1 = 4'b0110; dice2 = 4'b0111;  // 骰子1 = 6, 骰子2 = 7
		  #10
		  stop = 1;
		  #10
		  stop =0;
		  #10
        #50 dice1 = 4'b1000; dice2 = 4'b1001;  // 骰子1 = 8, 骰子2 = 9
        #50 dice1 = 4'b0000; dice2 = 4'b0000;  // 骰子1 = 0, 骰子2 = 0 (关闭显示)

        // 停止仿真
        #100 $finish;
    end
endmodule

`timescale 1ms / 10ns

module tb_dice;

    // 输入信号
    reg clk;
    reg rst;
    reg start1,start2;

    // 输出信号
    wire [7:0] row;   // 行控制信号
    wire [7:0] r_col; // 红色列控制信号
    wire [7:0] g_col; // 绿色列控制信号
	 wire clk_div;

    // 内部信号（通过访问模块内部）
    wire [3:0] dice1; // 第一个骰子信号
    wire [3:0] dice2; // 第二个骰子信号

    // 实例化被测模块（DUT: Device Under Test）
    dice uut (
        .rst(rst),
        .clk(clk),
        .start1(start1),
		  .start2(start2),
        .row(row),
        .r_col(r_col),
        .g_col(g_col),
		  .clk_div(clk_div),
		  .dice1(dice1),
		  .dice2(dice2)
    );


    // 时钟生成器
    initial clk = 0;
    always #0.5 clk = ~clk; // 时钟周期 1ms

    // 仿真逻辑
    initial begin

        rst=0;
        #10000;
		  
		  rst = 1;
        #1;          // 等待 10ns
        
        rst = 0;      // 释放复位信号
        #1; 

        $stop;      // 结束仿真
    end


endmodule

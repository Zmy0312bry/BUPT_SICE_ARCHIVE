`timescale 1ns / 1ps // 定义时间单位和精度   
module VI_III_JK_tb;   
// 定义测试平台输入和输出   
reg clk;   
reg rst_n;   
reg j, k;   
wire q, q_n;   
// 实例化被测模块   
VI_III_JK uut (   
.clk(clk),   
.rst_n(rst_n),   
.j(j),   
.k(k),   
.q(q),   
.q_n(q_n)   
);   
// 时钟信号生成   
initial begin   
clk = 0;   
forever #5 clk = ~clk; // 假设时钟周期为10ns   
end   
// 初始化输入信号   
initial begin   
// 初始化信号   
clk = 0;   
rst_n = 0;   
  j = 0;   
    k = 0;   
   
    // 等待一段时间后开始测试   
    #10;   
   
    // 释放复位   
    rst_n = 1;   
   
    // 测试序列   
    // 00: 不变   
    #10; j = 0; k = 0;   
    #10;   
   
    // 01: 复位   
    #10; j = 0; k = 1;   
    #10;   
   
    // 10: 置位   
    #10; j = 1; k = 0;   
    #10;   
   
    // 11: 翻转   
    #10; j = 1; k = 1;   
    #10;   
   
    // 重复翻转测试   
    #10; j = 1; k = 1;   
    #10;   
   
    // 回到初始状态   
    #10; j = 0; k = 0;   
    #13;   
   
    // 复位信号拉低   
    rst_n = 0;   
    #10;   
   
    // 释放复位，继续测试（如果需要）   
    rst_n = 1;   
   
    // ... 可以继续添加更多的测试序列   
   
    // 结束仿真  
    $finish;   
end     
endmodule 
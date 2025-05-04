`timescale 1ns / 1ps // 定义时间单位和精度

module six_point_two_dff_sync_tb;   
// 定义测试平台输入和输出   
    reg clk;
    reg rst_n;
    reg d;
    wire q;
// 实例化被测模块   
    six_point_two_dff_sync uut (   
        .clk(clk),   
        .rst_n(rst_n),   
        .d(d),   
        .q(q)   
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
        d = 0;   
   
        // 等待一段时间后开始测试   
        #10;   
        
        // 释放复位   
        rst_n = 1;   
    
        // 第一个测试周期：d 保持不变   
        #10; d = 0;   
        #10;   
    
        // 第二个测试周期：d 翻转   
        #10; d = 1;   
        #10;   
    
        // 第三个测试周期：d 再次翻转   
        #10; d = 0;   
        #10;   
    
        // 复位信号拉低   
        rst_n = 0;   
        #10;   
    
        // 释放复位，继续测试   
        rst_n = 1;   
    
        // 重复上述d的翻转测试   
        #10; d = 1;   
        #10;   
        #10; d = 0;   
        #10;   
    
        // 结束仿真   
        $finish;   
    end   
     
    initial begin   
    $dumpfile("6_2_tb.vcd");   
    $dumpvars(0, six_point_two_dff_sync_tb);   
    end   
endmodule 
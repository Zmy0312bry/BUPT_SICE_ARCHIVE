`timescale 1ns / 1ps

module wave_dac_tb;

// 测试台输入输出
reg clk;
reg rst_n;
wire [7:0] dac_out;

// 实例化被测试模块
wave_dac uut (
    .clk(clk),
    .rst_n(rst_n),
    .dac_out(dac_out)
);

// 时钟信号生成
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 产生周期为10ns的时钟信号
end

// 测试序列
initial begin
	 rst_n = 1;
	 #10;
    // 初始化输入
    rst_n = 0; 
    #20; // 持续20ns的复位
    
    rst_n = 1; // 释放复位
    #10000; // 观察500ns的波形输出
    
    $finish; // 结束仿真
end

initial begin
    $dumpfile("wave_dac_tb.vcd");
    $dumpvars(0, wave_dac_tb);
end

// 监控输出
initial begin
    $monitor("Time=%t, dac_out=%h",$time, dac_out);
end

endmodule

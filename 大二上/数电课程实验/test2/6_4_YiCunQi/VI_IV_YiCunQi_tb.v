`timescale 1ns / 1ps   
module VI_IV_YiCunQi_tb;   
// 输入输出信号定义   
reg clk;   
reg rst_n;   
reg din;   
wire [7:0] p_dout;   
wire s_dout;   
// 实例化被测试模块   
VI_IV_YiCunQi uut (   
.clk(clk),   
.rst_n(rst_n),  
.din(din),   
.p_dout(p_dout),   
.s_dout(s_dout)   
);   

// 初始化和时钟产生   
initial begin   
// 初始化   
clk = 0;   
rst_n = 0;   
din = 0;   
// 等待一段时间，然后释放复位   
#10 rst_n = 1;   
// 输入序列   
#10 din = 1;   
#10 din = 0;   
#10 din = 1;   
#10 din = 1;   
#10 din = 0;   
#10 din = 0;   
#10 din = 1;   
#10 din = 0;   
// 停止仿真   
#10 $finish;   
end   
// 时钟产生   
always #5 clk = ~clk;   
// 监视输出   
initial begin   
$monitor("Time = %t, clk = %b, rst_n = %b, din = %b, p_dout = %b, s_dout = %b", $time, clk, rst_n, din, p_dout, s_dout);   
end   
endmodule 
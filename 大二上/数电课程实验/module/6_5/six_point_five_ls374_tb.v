`timescale 1ns / 1ps   
module six_point_five_ls374_tb;   
// 输入输出端口声明   
reg [7:0] d_in;  
reg clk;   
reg oe_n;   
wire [7:0] d_out;   
// 实例化被测模块   
six_point_five_ls374 uut (   
.d_in(d_in),   
.clk(clk),   
.oe_n(oe_n),   
.d_out(d_out)   
);   
initial begin
$dumpfile("6_5_tb.vcd");
$dumpvars(0,six_point_five_ls374_tb);
end
// 时钟信号生成   
initial begin   
clk = 0;   
forever #10 clk = ~clk; // 假设时钟周期为20ns   
end   
// 初始化输入信号   
initial begin   
// 初始状态   
d_in = 8'h00;   
oe_n = 0; // 输出禁用   
#20; // 等待一个时钟周期以确保稳定   
// 启用输出，并改变输入数据   
oe_n = 1; // 启用输出   
#10 d_in = 8'hFF; // 写入全1   
#10 d_in = 8'hAA; // 写入01010101   
#10 d_in = 8'h55; // 写入01010101的反码   
// 再次禁用输出   
oe_n = 0; // 禁用输出   
#10;   
// 停止仿真（可选）   
#10 $finish;   
end   
// 监视输出信号（可选，用于调试）   
initial begin   
$monitor("Time = %t, clk = %b, oe_n = %b, d_in = %h, d_out = %h", $time, clk, oe_n, d_in, d_out);   
end  
endmodule 
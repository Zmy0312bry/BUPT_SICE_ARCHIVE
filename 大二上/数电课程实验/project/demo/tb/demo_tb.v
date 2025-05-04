// 时间单位：1ns，时间精度：1ps
`timescale 1ns/1ps
module demo_tb;
reg [3:0] key;
reg [3:0] sw;
wire [7:0] led;
demo test ( // 实例化demo模块
.key(key),
.sw(sw),
.led(led)
);
initial begin // 初始化输入信号并进行仿真
// 初始值
key = 4'b0000;
sw = 4'b0000;
// 每隔10ns，改变key与sw的值
#10 key = 4'b1010; sw = 4'b0101;
#10 key = 4'b1111; sw = 4'b0000;
#10 key = 4'b0011; sw = 4'b1100;
#10 key = 4'b1001; sw = 4'b0110;
// 结束仿真
#10 $stop;
end
// 监视输出信号
initial begin
$monitor("At time %t: key = %b, sw = %b, led = %b", $time,
key, sw, led);
end
endmodule
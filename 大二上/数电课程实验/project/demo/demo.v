// 模块名：demo
// 端口：key, sw, led
module demo(
input [3:0] key, // key：4位，按键输入
input [3:0] sw, // sw：4位，开关输入
output [7:0] led // led：8位，LED输出
);
assign led = {key, sw}; // 大括号为拼接符，key输出至led的高4位
endmodule
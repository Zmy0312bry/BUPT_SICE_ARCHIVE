module RGB_LED (sw,led);
input [2:0] sw; //开关输入信号，利用了其中3个开关
output [2:0] led; //输出信号到RGB LED
assign led = sw; //assign连续赋值。
endmodule
module shift_register_led( 
 input clk, // 12MHz 时钟输入 
 input rst_n, // 低电平有效的复位信号 
 output reg [7:0] led // 8 位 LED 输出，低电平点亮 
); 
// 分频器参数，用 1,200,000 作为分频因子，LED 大约每秒更新 8 次 
// 12MHz / 1,200,000 = 10Hz / 8 = 1.25Hz 
parameter DIV_FACTOR = 1200000; 
 
// 分频计数器 
reg [23:0] counter = 0; 
 
// 流水灯状态控制 
always @(posedge clk or negedge rst_n) begin 
 if (!rst_n) begin 
 // 复位时，所有 LED 关闭（但因为是低电平点亮，所以这里输出高电平） 
 led <= 8'b0111_1111; 
 counter <= 0; 
 end else begin 
 // 分频 
 if (counter >= DIV_FACTOR - 1) begin 
 counter <= 0; 
 // 更新 LED 状态，左移一位，并在溢出时回到最低位 
 led <= {led[6:0], led[7]}; 
 end else begin 
 counter <= counter + 1; 
 end 
 end 
end 
endmodule
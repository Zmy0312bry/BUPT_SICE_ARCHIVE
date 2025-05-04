module test3_4_4 (clk,rst,key,led);
input clk;
input rst;
input key;
output reg led; 
wire key_pulse;
//当按键按下时产生一个高电平脉冲，翻转一次 led
 always @(posedge clk or negedge rst) begin
 if (!rst)
 led <= 1'b1;
 else if (key_pulse)
 led <= ~led;
 else
 led <= led;
end 
wire pb_down;
wire pb_up;
//例化消抖 module，这里没有传递参数 N，采用了默认的 N=1 
 Debouncer u1( 
 .clk(clk), // 输入时钟信号，12MHz 
 .PB(key), // 按键信号，被按下时为低电平 
 .PB_state(key_pulse), // 只要按键被按下，此输出就为高电平 
 .PB_down(pb_down), // 按下按键时，输出高电平，宽度为一个时钟周期
 .PB_up(pb_up) // 释放按键时，输出高电平，宽度为一个时钟周期
 );
endmodule
module Debouncer( 
 input clk, // 输入时钟信号，10MHz 
 input PB, // 按键信号，被按下时为低电平 
 output reg PB_state, // 只要按键被按下，此输出就为高电平 
 output PB_down, // 当按键被按下时，输出高电平，宽度为一个时钟周期
 output PB_up // 当按键被释放时，输出高电平，宽度为一个时钟周期
); 
// 使用两个触发器将 PB 信号与同步到时钟域
reg PB_sync_0; 
always @(posedge clk) PB_sync_0 <= ~PB; //PB_sync_0=1 按键被按下 
reg PB_sync_1; 
always @(posedge clk) PB_sync_1 <= PB_sync_0; 
 
reg [17:0] PB_cnt; // 声明一个 18 位的计数器，在 12MHz 时钟下计时约 22ms
 
// 当按键按下或释放时，递增计数器，达到最大值时，则认为按键状态发生变化
wire PB_idle = (PB_state==PB_sync_1); //二者相等表示按键处于空闲状态 
wire PB_cnt_max = &PB_cnt; // 当 PB_cnt 的所有位都为 1 时此信号为真 
 
always @(posedge clk) 
if (PB_idle) 
 PB_cnt <= 0; // 若无按键按下，计数器清零 
else 
begin 
 PB_cnt <= PB_cnt + 16'd1; // 若按键按下，则递增计数器 
 if (PB_cnt_max)
PB_state <= ~PB_state; // 若计数到最大值则更新 PB_state 状态 
end 
// 当按键从释放变为按下状态时，PB_down 为高电平，宽度为一个时钟周期
assign PB_down = ~PB_idle & PB_cnt_max & ~PB_state;
// 当按键从按下变为释放状态时，PB_up 为高电平，宽度为一个时钟周期 
assign PB_up = ~PB_idle & PB_cnt_max & PB_state;
endmodule
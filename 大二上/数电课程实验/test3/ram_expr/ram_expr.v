module ram_expr(
	input clk,
	input rst,
	input write,
	input [3:0] addr,
	output [8:0] segment_led_1,
	output [8:0] segment_led_2,
	input num
	
);
	reg [3:0] number;
	wire [3:0] data_out;
	wire num_pulse;
	wire write_pulse;
	
	debounce dbs1(
	.clk(clk),
	.rst(rst),
	.key(num),
	.key_pulse(num_pulse)
	);
	
	debounce dbs2(
	.clk(clk),
	.rst(rst),
	.key(write),
	.key_pulse(write_pulse)
	);
	
	ram rx(
	.clk(clk),
	.addr(addr),
	.we(write_pulse),
	.data_in(number),
	.data_out(data_out)
	);
	
	segment seg(
	.seg_data_1(number),
	.seg_data_2(data_out),
	.segment_led_1(segment_led_1),
	.segment_led_2(segment_led_2)
	);
	initial begin
		number = 4'h0;
	end
	always@(posedge clk or negedge rst)begin
		if (!rst) begin
			number <= 4'h0;
		end else if (num_pulse) begin
			number <= number + 4'h1;
		end
	end

endmodule

module segment 
( 
input wire [3:0] seg_data_1, //四位输入数据信号 
input wire [3:0] seg_data_2, //四位输入数据信号 
output wire [8:0] segment_led_1, //数码管 1，MSB~LSB = SEG,DP,G,F,E,D,C,B,A 
output wire [8:0] segment_led_2 //数码管 2，MSB~LSB = SEG,DP,G,F,E,D,C,B,A 
); 
reg [8:0] seg [15:0]; //存储7段数码管译码数据 
initial begin 
seg[0]  = 9'h3f; // 0 
seg[1]  = 9'h06; // 1 
seg[2]  = 9'h5b; // 2 
seg[3]  = 9'h4f; // 3 
seg[4]  = 9'h66; // 4 
seg[5]  = 9'h6d; // 5 
seg[6]  = 9'h7d; // 6 
seg[7]  = 9'h07; // 7 
seg[8]  = 9'h7f; // 8 
seg[9]  = 9'h6f; // 9 
seg[10] = 9'h77; // A 
seg[11] = 9'h7C; // b 
seg[12] = 9'h39; // C 
seg[13] = 9'h5e; // d 
seg[14] = 9'h79; // E 
seg[15] = 9'h71; // F 
end 
assign segment_led_1 = seg[seg_data_1];  
assign segment_led_2 = seg[seg_data_2];  
endmodule 


module debounce (clk,rst,key,key_pulse);
parameter N = 1; //要消除的按键的数量
 input clk;
 input rst;
 input [N-1:0] key; //输入的按键 
 output [N-1:0] key_pulse; //按键动作产生的脉冲
 reg [N-1:0] key_rst_pre; //存储上一个触发时的按键值
 reg [N-1:0] key_rst; //储存储当前时刻触发的按键值
 wire [N-1:0] key_edge; //按键由高到低变化时产生一个高脉冲
//利用非阻塞赋值特点，将两个时钟触发的按键状态存储在两个寄存器变量中
 always @(posedge clk or negedge rst) begin
 if (!rst) begin
 key_rst <= {N{1'b1}}; //初始化时给 key_rst 赋值全为 1
 key_rst_pre <= {N{1'b1}};
 end
 else begin
//第一个时钟上升沿将 key 的值赋给 key_rst,同时 key_rst 的值赋给 key_rst_pre
//非阻塞赋值，相当于经过两个时钟触发，key_rst 存储当前时刻 key 的值，key_rst_pre 存储前一个时钟的 key 的值
key_rst <= key; 
key_rst_pre <= key_rst; 
 end 
 end
 //脉冲边沿检测。当 key 检测到下降沿时，key_edge 产生一个时钟周期的高电平
 assign key_edge = key_rst_pre & (~key_rst);
 reg [17:0] cnt; //产生延时所用的计数器，系统时钟 12MHz 
 //产生 20ms 延时，当检测到 key_edge 有效是计数器清零开始计数
 always @(posedge clk or negedge rst) begin
 if(!rst)
 cnt <= 18'h0;
 else if(key_edge)
 cnt <= 18'h0;
 else
 cnt <= cnt + 1'h1;
 end 
 reg [N-1:0] key_sec_pre; //延时后检测电平寄存器变量
 reg [N-1:0] key_sec; 
 //延时后检测 key，如果按键状态变低则按键有效，产生一个时钟周期的高电平。
 always @(posedge clk or negedge rst) begin
 if (!rst)
 key_sec <= {N{1'b1}}; 
 else if (cnt==18'h3ffff)
 key_sec <= key; 
 end
 always @(posedge clk or negedge rst)begin
 if (!rst)
key_sec_pre <= {N{1'b1}};
 else 
 key_sec_pre <= key_sec; 
 end
 assign key_pulse = key_sec_pre & (~key_sec); 
endmodule

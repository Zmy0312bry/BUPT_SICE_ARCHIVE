module is_roll(                   //测试模块用于根据时钟信号，每0.2秒进行扔骰子操作
	 input clk, //时钟选择1kHz
    input wire rst,          // 复位信号
    output [3:0] dice1,   // 输出随机数（0-9）
	 output [3:0] dice2,
	 output reg clk_div,
	 input start1,start2
);

reg roll1,roll2;  //设置start信号，由时钟控制
reg [9:0] count;  //20计数器，即选择5位
reg cnt;


initial begin
	count <= 10'b0000_0000;
	roll1 <= 1'b0;
	roll2 <= 1'b0;
	cnt <= 1'b0;
end

    // 实例化第二个随机数生成器
    random2 u_random2 (
        .clk(clk),
		  .rst(rst),        // 连接复位信号
        .roll(roll2),      // 连接掷骰子触发信号
        .dice(dice2)      // 连接第二个骰子的随机数输出
    );
	 
	 	     // 实例化第一个随机数生成器
    random u_random1 (
        .clk(clk),
		  .rst(rst),        // 连接复位信号
        .roll(roll1),      // 连接掷骰子触发信号
        .dice(dice1)      // 连接第一个骰子的随机数输出
    );

always @(posedge clk or posedge rst) begin
	clk_div <= start;
    if (rst) begin
        roll1 <= 1'b0;
		  roll2 <= 1'b0;
        count <= 10'b0;
    end else if (count < 10'd100) begin
        count <= count + 1;
        roll1 <= 0;
		  roll2 <= 0;
    end else begin
        count <= 10'b0;
        roll1 <= start1;  // 触发掷骰子
		  roll2 <= start2;
    end
end


endmodule			 
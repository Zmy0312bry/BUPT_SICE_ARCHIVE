module dice(row,r_col,g_col,rst,clk,start1,start2,clk_div,dice1,dice2,signal,cat,rgb_led);
	input rst;
	input clk;
	input start1,start2;
	output [7:0] row; //行控制信号
	output [7:0] r_col; //红色列控制信号
	output [7:0] g_col; //绿色列控制信号
	output clk_div;
	output [3:0] dice1,dice2;
	output [7:0] signal;
	output [7:0] cat;
	output [15:0] rgb_led;

	wire [3:0]score1,score2;
	wire btn_out;
	wire divided_clk;
	wire times;
	wire is_final;
	wire finish;
	
	prescaler #(
  .DIVIDE_BY(1000)
) u_prescaler (
  .clk_in(clk),
  .rst(reset),
  .clk_out(divided_clk)
);

	debounce_double uut_debounce(
		.stop(times),
		.clk(clk),
		.btn_in(start1),
		.btn_out(btn_out)
	);
	
	segment u_segment(
		.clk(clk),
		.score1(score1),
		.score2(score2),
		.cat(cat),
		.signal(signal)
	);
	
	is_roll u_roll(
		.clk(divided_clk),
		.rst(rst),
		.dice1(dice1),
		.dice2(dice2),
		.clk_div(clk_div),
		.start1(start1),
		.start2(start2),
		.finish(finish)
	);

	 
	 // 实例化 dot_matrix 模块
    dot_matrix u_dot_matrix (
        .clk(clk),        // 连接时钟信号
        .rst(rst),        // 连接复位信号
        .dice1(dice1),    // 连接第一个骰子的输入
        .dice2(dice2),    // 连接第二个骰子的输入
        .row(row),        // 连接行信号输出
        .r_col(r_col),    // 连接红色列信号输出
        .g_col(g_col),     // 连接绿色列信号输出
		  .stop(times)
    );

// 实例化standby模块
standby standby_inst (
  .clk(clk),
  .times(times),
  .is_final(is_final),
  .rst(rst),
  .score1(score1),
  .score2(score2),
  .rgb_led(rgb_led),
  .is_finish(finish)
);
	 
// 实例化socre模块
score socre_inst (
   .clk(clk),
   .start1(start1),
   .start2(start2),
   .dice1(dice1),
   .dice2(dice2),
   .state1(score1),
   .state2(score2),
   .times(times),
   .is_final(is_final),
	.finish(finish),
	.rst(rst)
);	 

endmodule
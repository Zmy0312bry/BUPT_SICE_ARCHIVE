module VII_III_74HC595_latch (
	input clk,
	input clk_btn,          // sck        按下时数据读入      & 按钮
	input si,               // si         输入的一位信号      & 拨码开关
	input data_print,       // data_print 将数据转移到寄存器中 & 按钮
	input rst,
	output [7:0] sn_status, // sn_status  展示移存器的内部状态 & 8个LED
	output [7:0] seg1,      // seg1&seg2  两个7段数码管，用于将& segment1 & segment2
	output [7:0] seg2       // 寄存器结果分成两个4位输出
);
	wire clk_btn_pulse;
	wire data_print_pulse;
	// wire [7:0] shift_dffs;
	wire [7:0] storage;

	debounce dbn1(
	.clk(clk),
	.rst(rst),
	.key(clk_btn),
	.key_pulse(clk_btn_pulse)
	);

	debounce dbn2(
	.clk(clk),
	.rst(rst),
	.key(data_print),
	.key_pulse(data_print_pulse)
	);

	hc595 hc(
	.sclr_n(rst),
	.si(si),
	.sck(clk_btn_pulse),
	.rck(data_print_pulse),
	.g_n(0),
	.shift_dffs(sn_status),
	.q(storage),
	.qh_qout()
	);
	
	seven_segment_decoder seg_1(
	.en(1),
	.digit_in(storage[7:4]),
	.seg(seg1),
	);
	
	seven_segment_decoder seg_2(
	.en(1),
	.digit_in(storage[3:0]),
	.seg(seg2),
	);
endmodule
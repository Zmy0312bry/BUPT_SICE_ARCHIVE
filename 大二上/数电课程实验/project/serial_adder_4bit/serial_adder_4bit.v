module serial_adder_4bit(
	input wire clk,
	input rst,
	input wire input_digit,
	input wire calculate,
	input wire cin, // 低位来的进位
	input [3:0] input_number,
	output reg cin_led,
	output reg [1:0] status_led,
	output [7:0] segout_1,segout_2, // 加法运算的结果
	output cout_led // 最高位的进位
);
	wire button,calc,cin_pulse;
	wire [3:0] result;
	Debounce module_1(
		.clk(clk),
		.rst(rst),
		.key(input_digit),
		.key_pulse(button),
	);
	Debounce module_2(
		.clk(clk),
		.rst(rst),
		.key(calculate),
		.key_pulse(calc),
	);
	Debounce module_3(
		.clk(clk),
		.rst(rst),
		.key(cin),
		.key_pulse(cin_pulse),
	);
	two_point_two_seven_segment_decoder Decoder(
		.digit_in(number),
		.seg_out_1(segout_1),
		.seg_out_2(segout_2)
	);
	five_point_eight_threading_adder adder(
		.A(number),
		.B(input_number),
		.Cin(cin_led),
		.S(result),
		.Cout(cout_led),
	);
	reg [3:0] number;
	always @(posedge clk) begin
		if (button) begin
			number <= input_number;
			status_led[0] <= ~status_led[0];
		end 
		if (calc) begin
			number <= result;
			status_led[1] <= ~status_led[1];
		end 
		if (cin_pulse)
			cin_led <= ~ cin_led;
		else
			cin_led <= cin_led;
	end

endmodule
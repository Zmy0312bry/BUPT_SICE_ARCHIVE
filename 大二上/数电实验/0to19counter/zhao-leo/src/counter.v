module counter(
	input btn,
	input rst,
	input wire clk,
	output [6:0] led_signal,
	output [1:0] select_led,
	output reg [5:0] other_led
);
	reg [3:0] number_seg = 0;
	reg [4:0] number = 19;
	wire div_clk;
	wire btn_state;
	wire [3:0] bcd_tens;
	wire [3:0] bcd_ones;
	reg flag = 0;
	initial begin
		other_led = 6'b111_111;
	end
	
	debounce dbunce(
	.clk(clk),
	.input_btn(btn),
	.output_btn(btn_state)
	);

	div_100 divclk(
		.clk(clk),
		.rst(rst),
		.div_clk(div_clk)

	);

	binary_bcd binbcd(
		.bin(number),
		.bcd_tens (bcd_tens),
		.bcd_ones (bcd_ones)
	);
	
	led_select ledslt(
		.clk(clk),
		.select(select_led)
	);
	
	segment7 seg_ment7(
	.num(number_seg),
	.seg7(led_signal)
	);
	// 点亮LED
	always @(negedge clk or posedge rst) begin
		if (rst) begin
			number_seg = 0;
		end else if (select_led == 2'b10) begin
			number_seg = bcd_tens;
		end else begin
			number_seg = bcd_ones;
		end
	end
	
	always @(negedge div_clk or posedge btn_state or posedge rst) begin
		if (rst) begin
			number = 19;
		end else if (btn_state) begin
			flag = ~flag;
		end else if (number >= 19) begin
			number = 0;
		end else if (flag == 0) begin
			number = number + 1;
		end
	end
	
endmodule
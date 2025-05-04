module welcome2025(
	input clk,
	output [7:0] segment1,
	output [7:0] segment2
);
	wire clk_out;
	
	clk_divider divider(
	.clk_in(clk),
	.rst_n(1'b1),
	.clk_out(clk_out)
	);
	
	reg [3:0] number_1;
	reg [3:0] number_2;
	
	seven_segment_decoder seg1(
	.en(1'b1),
	.digit_in(number_1),
	.seg(segment1)
	);
	
	seven_segment_decoder seg2(
	.en(1'b1),
	.digit_in(number_2),
	.seg(segment2)
	);
	
	reg [15:0] number;
	initial begin
		number = 16'h2025;
		
		number_1 = 4'h0;
		number_2 = 4'b0;
	end
	
	always @(posedge clk_out) begin
		number_1 = number[3:0];
		number_2 = number[7:4];
		number = {number[3:0],number[15:4]};
	end
endmodule
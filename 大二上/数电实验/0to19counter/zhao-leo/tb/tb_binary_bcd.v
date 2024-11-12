`timescale 1ms / 1ps
 
module binary_bcd_test;
 
	reg [4:0] bin;
	wire [3:0] bcd_tens;
	wire [3:0] bcd_ones;
initial begin   
	$dumpfile("tb_binary_bcd.vcd");   
	$dumpvars(0, binary_bcd_test);   
end 
initial begin
	bin = 5'b0_0000; //十进制0
	#100
	bin = 5'b0_0001; //十进制1
	#100
	bin = 5'b1_0011; //十进制19
	#100
	bin = 5'b0_1000; //十进制8
	#100
	bin = 5'b0_1010; //十进制10
	#100
	$finish;
end
binary_bcd uut(
	.bin(bin),
	.bcd_tens (bcd_tens),
	.bcd_ones (bcd_ones)
);
endmodule
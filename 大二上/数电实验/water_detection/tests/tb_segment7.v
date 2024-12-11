`timescale 1ms / 1ps
 
module segment7_test;
 
	reg [3:0] bin;
	reg dp_in;
	wire dp;
	wire [6:0] seg7;
	initial begin   
		$dumpfile("tb_segment7.vcd");   
		$dumpvars(0, segment7_test);   
	end 
initial begin
	dp_in = 0;
	bin = 4'b0000; //十进制0
	#100
	bin = 4'b0001; //十进制1
	#100
	bin = 4'b0010; //十进制2
	#100
	bin = 4'b0011; //十进制3
	#100
	bin = 4'b0100; //十进制4
	#100
	bin = 4'b0101; //十进制5
	#100
	bin = 4'b0110; //十进制6
	#100
	bin = 4'b0111; //十进制7
	#100
	bin = 4'b1000; //十进制8
	#100
	bin = 4'b1001; //十进制9
	#100
	bin = 4'b1010; //十进制10
	#100
	dp_in = 1;
	#100
	$finish;
end
segment7 uut(
	.num(bin),
	.seg7(seg7),
	.dp_in(dp_in),
	.dp(dp)
);
endmodule
`timescale 1ns/1ps
module tb_full_adder;
	reg a,b,cin;
	wire sum,cout;
	initial begin
		a = 0;
		b = 0;
		cin = 0;
	end
	
	V_II_74LS138 uut(
		.a(a),
		.b(b),
		.cin(cin),
		.sum(sum),
		.cout(cout)
	);
	
	initial begin
		#10;
		a = 1;
		#10;
		a = 0;
		b = 1;
		#10;
		a = 0;
		b = 0;
		cin = 1;
		#10;
		a = 1;
		#10;
		a = 0;
		b = 1;
		#10;
		a = 1;
		#10;
		$finish;
	end
endmodule
		
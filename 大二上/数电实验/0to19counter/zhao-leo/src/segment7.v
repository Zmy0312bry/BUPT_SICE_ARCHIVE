module segment7(
	input [3:0] num,
	output reg [6:0] seg7
);
	always @(num) begin
		case(num)
			4'b0000:seg7=7'b1111110;
			4'b0001:seg7=7'b0110000;
			4'b0010:seg7=7'b1101101;
			4'b0011:seg7=7'b1111001;
			4'b0100:seg7=7'b0110011;
			4'b0101:seg7=7'b1011011;
			4'b0110:seg7=7'b1011111;
			4'b0111:seg7=7'b1110000;
			4'b1000:seg7=7'b1111111;
			4'b1001:seg7=7'b1111011;
			default:seg7=7'b0000000;
		endcase
	end
endmodule
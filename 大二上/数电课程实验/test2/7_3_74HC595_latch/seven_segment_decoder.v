module seven_segment_decoder (digit_in,en,seg);
 input en; 
 input [3:0] digit_in; // 输入 4 位 8421BCD 码
 output [7:0] seg; // 输出 7 位段选信号 g~a
 reg [7:0] seg_out;
 initial begin
 seg_out = 8'h00;
 end
// 最高位为位选信号，为 0 时允许七段数码管工作
always @ (*)
begin
 case (digit_in)
 4'b0000: seg_out = 8'b0011_1111; // 0
 4'b0001: seg_out = 8'b0000_0110; // 1
 4'b0010: seg_out = 8'b0101_1011; // 2
 4'b0011: seg_out = 8'b0100_1111; // 3
 4'b0100: seg_out = 8'b0110_0110; // 4
 4'b0101: seg_out = 8'b0110_1101; // 5
 4'b0110: seg_out = 8'b0111_1101; // 6
 4'b0111: seg_out = 8'b0000_0111; // 7
 4'b1000: seg_out = 8'b0111_1111; // 8
 4'b1001: seg_out = 8'b0110_1111; // 9
 4'b1010: seg_out = 8'b0111_0111; // A
 4'b1011: seg_out = 8'b0111_1100; // b
 4'b1100: seg_out = 8'b0011_1001; // C
 4'b1101: seg_out = 8'b0101_1110; // d
 4'b1110: seg_out = 8'b0111_1001; // E
 4'b1111: seg_out = 8'b0111_0001; // F
 default: seg_out = 8'bzzzz_zzzz;
 endcase
end
assign seg = en ? seg_out:8'bzzzz_zzzz;
endmodule
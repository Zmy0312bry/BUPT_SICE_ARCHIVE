/*
 * @Author: zhao-leo 18055219130@163.com
 * @Date: 2024-10-18 21:32:58
 * @LastEditors: zhao-leo 18055219130@163.com
 * @LastEditTime: 2024-10-18 21:33:16
 * @FilePath: \module\2_2\two_point_two_seven_segment_decoder.v
 */
module two_point_two_seven_segment_decoder (digit_in, seg_out);
    input [3:0] digit_in; // 输入 4 位 8421BCD 码
    output reg [7:0] seg_out; // 输出 7 位段选信号 g~a
    // 最高位为位选信号，为 0 时允许七段数码管工作
    always @ (digit_in) begin
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
            default: seg_out = 8'b10000000; // 默认数码管不显示
        endcase
    end
endmodule

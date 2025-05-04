module seven_segment_decoder(in, seg_led);
    input [2:0] in;             // 8421BCD码
    output reg [8:0] seg_led;   // 输出管脚
    always @(*)
    case(in)
        3'b000: seg_led = 9'h3f;
        3'b001: seg_led = 9'h06;
        3'b010: seg_led = 9'h5b;
        3'b011: seg_led = 9'h4f;
        3'b100: seg_led = 9'h66;
        3'b101: seg_led = 9'h6d;
        3'b110: seg_led = 9'h7d;
        3'b111: seg_led = 9'h07;
        default: seg_led = 9'h00;
    endcase
endmodule
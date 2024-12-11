module kv_map(
    input [3:0] key,
    output reg [3:0] value  //将4*4的键盘映射到8421BCD码&点和清零
);

always @(*) begin
    case(key)
        4'b0000: value = 4'b0000; //0
        4'b1100: value = 4'b0001; //1
        4'b1101: value = 4'b0010; //2
        4'b1110: value = 4'b0011; //3
        4'b1000: value = 4'b0100; //4
        4'b1001: value = 4'b0101; //5
        4'b1010: value = 4'b0110; //6
        4'b0100: value = 4'b0111; //7
        4'b0101: value = 4'b1000; //8
        4'b0110: value = 4'b1001; //9

        4'b0001: value = 4'b1010; //dot
        4'b0010: value = 4'b1011; //reset
        default: value = 4'b1111;
    endcase
end
endmodule
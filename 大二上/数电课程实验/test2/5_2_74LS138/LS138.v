module LS138 (
    input wire G1,            // 高电平使能端
    input wire G2A,           // 低电平使能端1
    input wire G2B,           // 低电平使能端2
    input wire [2:0] address, // 地址线
    output reg [7:0] outputs  //输出端，低电平有效
);
    always @(*) begin //所有变量都是敏感变量
        if (G1 & ~G2A & ~G2B) begin
            case (address)
                3'b000: outputs = 8'b11111110;
                3'b001: outputs = 8'b11111101;
                3'b010: outputs = 8'b11111011;
                3'b011: outputs = 8'b11110111;
                3'b100: outputs = 8'b11101111;
                3'b101: outputs = 8'b11011111;
                3'b110: outputs = 8'b10111111;
                3'b111: outputs = 8'b01111111;
                default: outputs = 8'b11111111;
            endcase
        end else begin
            outputs = 8'b11111111;
        end
    end
endmodule
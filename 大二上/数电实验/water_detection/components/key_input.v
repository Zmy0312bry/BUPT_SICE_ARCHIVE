module key_input(
    input wire clk,      //1khz
    input wire [3:0] row,
    output reg [3:0] col,
    output reg [3:0] key //已经消抖并且产生一周期信号的脉冲，默认空信号为1111
);
    reg [3:0] key_unconfirmed;
    reg [31:0] counter;
    reg [3:0] key_pre;
initial begin 
    col = 4'b1110;
    counter = 0;
    key_pre = 4'b1111;
    key_unconfirmed = 4'b1111;
    key = 4'b1111;
end

always @(negedge clk) begin
    col <= {col[2:0],col[3]}; 
end

always @(posedge clk) begin
    case(row)
        4'b1110: begin
            case(col)
                4'b1110: key_unconfirmed = 4'b0000;
                4'b1101: key_unconfirmed = 4'b0001;
                4'b1011: key_unconfirmed = 4'b0010;
                4'b0111: key_unconfirmed = 4'b0011;
            endcase
        end
        4'b1101: begin
            case(col)
                4'b1110: key_unconfirmed = 4'b0100;
                4'b1101: key_unconfirmed = 4'b0101;
                4'b1011: key_unconfirmed = 4'b0110;
                4'b0111: key_unconfirmed = 4'b0111;
            endcase
        end
        4'b1011: begin
            case(col)
                4'b1110: key_unconfirmed = 4'b1000;
                4'b1101: key_unconfirmed = 4'b1001;
                4'b1011: key_unconfirmed = 4'b1010;
                4'b0111: key_unconfirmed = 4'b1011;
            endcase
        end
        4'b0111: begin
            case(col)
                4'b1110: key_unconfirmed = 4'b1100;
                4'b1101: key_unconfirmed = 4'b1101;
                4'b1011: key_unconfirmed = 4'b1110;
                4'b0111: key_unconfirmed = 4'b1111;
            endcase
        end
        default: key_unconfirmed = 4'b1111;
    endcase
end

always@(negedge clk) begin
    if (key_unconfirmed != 4'b1111) begin
        if (key_pre == key_unconfirmed) begin
            if (counter == 60) begin
                key = key_unconfirmed;
                counter = 0;
            end else begin
                counter = counter + 1;
            end
        end else begin
            counter = 0;
            key_pre = key_unconfirmed;
        end
    end else begin
        key = 4'b1111;
    end
end

endmodule
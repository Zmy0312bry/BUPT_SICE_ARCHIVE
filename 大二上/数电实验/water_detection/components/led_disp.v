module led_disp(
    input clk,            //1khz
    input [3:0] key,
    output [7:0] select,
    output [6:0] segment7x,
    output reg [31:0] number,
    output reg [7:0] dp_list,
    output dp
);
    
    reg first_number;
    reg dp_move;
    wire [3:0] key;

    reg dp_in;
    reg [3:0] num;
    initial begin
        first_number = 1'b0;
        number = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
        dp_list = 8'b0000_0001;
        dp_move = 1'b0;
        dp_in = 0;
        num = 4'b0000;
    end
    always @(key) begin
        if (key != 4'b1111) begin
            if (key == 4'b1011) begin
                number = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
                dp_list = 8'b0000_0001;
                first_number = 1'b0;
                dp_move = 1'b0;
            end else if (key == 4'b1010) begin
                dp_move = 1'b1;
            end else if(key != 4'b0000 && first_number == 1'b0) begin
                number = {28'b1111_1111_1111_1111_1111_1111_1111,key};
                first_number = 1'b1;
            end else if (key == 4'b0000 && first_number == 1'b0 && dp_move == 1'b1) begin
                number = {28'b1111_1111_1111_1111_1111_1111_1111,key};
                first_number = 1'b1;
            end else begin
                if (dp_move == 1'b1) begin
                    dp_list = {dp_list[6:0],dp_list[7]};
                end
                number = {number[27:0],key};
            end
        end
    end
    select_disp slct(
        .clk(clk),
        .rst_n(),
        .out(select)
    );
    segment7 decoder(
        .num(num),
        .dp_in(dp_in),
        .seg7(segment7x),
        .dp(dp)

    );
    always@(select) begin
        case(select)
        8'b1111_1110:begin num = number[3:0]; dp_in = dp_list[0];end
        8'b1111_1101:begin num = number[7:4]; dp_in = dp_list[1];end
        8'b1111_1011:begin num = number[11:8]; dp_in = dp_list[2];end
        8'b1111_0111:begin num = number[15:12]; dp_in = dp_list[3];end
        8'b1110_1111:begin num = number[19:16]; dp_in = dp_list[4];end
        8'b1101_1111:begin num = number[23:20]; dp_in = dp_list[5];end
        8'b1011_1111:begin num = number[27:24]; dp_in = dp_list[6];end
        8'b0111_1111:begin num = number[31:28]; dp_in = dp_list[7];end
        default: begin num = 4'b0000; dp_in = 0; end
        endcase
    end
endmodule

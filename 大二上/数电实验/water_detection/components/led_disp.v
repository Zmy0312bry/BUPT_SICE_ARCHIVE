module led_disp(
    input clk,            //1khz
    input [3:0] key,
    output [7:0] select,
    output [6:0] segment7x,
    output [7:0] number_out,
    output dp,
    input [1:0] Anime_state,
    input [3:0] state
);

    reg [3:0] num;
    reg [11:0] number;
    reg dp_in;
    wire [3:0] select_n;
    initial begin
        number = 12'hfff;
        num = 4'b0000;
        dp_in = 1'b0;
    end
    always @(negedge clk) begin
        if (key != 4'b1111) begin
            if (key == 4'b1011) begin
                number = 12'hfff;
            end else begin
                number = {number[7:0],key};
            end
        end
    end
    select_disp slct(
        .clk(clk),
        .rst_n(1'b1),
        .out(select_n)
    );
    segment7 decoder(
        //.clk(clk),
        .dp_in(dp_in),
        .num(num),
        .seg7(segment7x),
        .dp(dp)

    );
    assign number_out = number[11:4];
    assign select = {select_n[3],4'b1111,select_n[2:0]};

	 
    always@(select_n) begin
        case(select_n)
        4'b1110:begin
            num <= number[3:0];
            dp_in<=1'b0;
        end
        4'b1101:begin
            num <= number[7:4];
            dp_in<=1'b1;
        end
        4'b1011:begin
            num <= number[11:8];
            dp_in<=1'b0;
        end
        4'b0111:begin
            if (state == 3'b111) begin
                case(Anime_state)
                2'b00:begin num = 4'b0001; dp_in<=1'b0;end
                2'b01:begin num = 4'b0010; dp_in<=1'b0;end
                2'b10:begin num = 4'b0011; dp_in<=1'b0;end
                endcase
            end else begin
                num <= 4'b1111;
                dp_in<=1'b0;
            end
        end
        default: begin num = 4'b1111; dp_in<=1'b0;end
        endcase
    end
endmodule

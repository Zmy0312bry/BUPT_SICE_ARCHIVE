module digi_screen
(
    input wire clk,
    input [63:0] PICTURE_G, // 64*64 picture
    input [63:0] PICTURE_R, // 64*64 picture  https://xantorohara.github.io/led-matrix-editor
    output reg [7:0] row,
    output reg [7:0] col_r,
    output reg [7:0] col_g
);
    initial begin
        row = 8'b0111_1111;
    end

    always@(negedge clk) begin //scan row
        row <= {row[6:0], row[7]};

    end

    always@(negedge clk) begin //scan col
        case(row)
        8'b1111_1110: begin
            col_r <= PICTURE_R[15:8];
            col_g <= PICTURE_G[15:8];
        end
        8'b1111_1101: begin
            col_r <= PICTURE_R[23:16];
            col_g <= PICTURE_G[23:16];
        end
        8'b1111_1011: begin
            col_r <= PICTURE_R[31:24];
            col_g <= PICTURE_G[31:24];
        end
        8'b1111_0111: begin
            col_r <= PICTURE_R[39:32];
            col_g <= PICTURE_G[39:32];
        end
        8'b1110_1111: begin
            col_r <= PICTURE_R[47:40];
            col_g <= PICTURE_G[47:40];
        end
        8'b1101_1111: begin
            col_r <= PICTURE_R[55:48];
            col_g <= PICTURE_G[55:48];
        end
        8'b1011_1111: begin
            col_r <= PICTURE_R[63:56];
            col_g <= PICTURE_G[63:56];
        end
        8'b0111_1111: begin
            col_r <= PICTURE_R[7:0];
            col_g <= PICTURE_G[7:0];
        end
        default: begin
            col_r <= 8'h00;
            col_g <= 8'h00;
        end
        endcase
    end

endmodule
module digi_screen
(
    input wire clk,
    input [63:0] PICTURE_G, // 64*64 picture
    input [63:0] PICTURE_R, // 64*64 picture  https://xantorohara.github.io/led-matrix-editor
    output reg [7:0] n_row,
    output reg [7:0] col_r,
    output reg [7:0] col_g
);
    reg [7:0] row;
    initial begin
        row = 8'b1000_0000;
        n_row = 8'b0111_1111;
    end

    always@(negedge clk) begin //scan row
        n_row <= {row[6:0], row[7]};
        row <= {row[6:0], row[7]};

    end

    always@(negedge clk) begin //scan col
        case(row)
        8'b0000_0001: begin
            col_r <= PICTURE_R[15:8];
            col_g <= PICTURE_G[15:8];
        end
        8'b0000_0010: begin
            col_r <= PICTURE_R[23:16];
            col_g <= PICTURE_G[23:16];
        end
        8'b0000_0100: begin
            col_r <= PICTURE_R[31:24];
            col_g <= PICTURE_G[31:24];
        end
        8'b0000_1000: begin
            col_r <= PICTURE_R[39:32];
            col_g <= PICTURE_G[39:32];
        end
        8'b0001_0000: begin
            col_r <= PICTURE_R[47:40];
            col_g <= PICTURE_G[47:40];
        end
        8'b0010_0000: begin
            col_r <= PICTURE_R[55:48];
            col_g <= PICTURE_G[55:48];
        end
        8'b0100_0000: begin
            col_r <= PICTURE_R[63:56];
            col_g <= PICTURE_G[63:56];
        end
        8'b1000_0000: begin
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
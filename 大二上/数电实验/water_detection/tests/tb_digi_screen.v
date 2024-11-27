`timescale 1ns/1ps

module digi_screen_test;
    
    reg clk_in;
    wire [7:0] row;
    wire [7:0] col_r;
    wire [7:0] col_g;
    
    digi_screen digi_screen_red (
        .PICTURE_G(64'ha4e4ffe4e4bf1e3f),
        .PICTURE_R(64'h0000000000000000),
        .clk(clk_in),
        .n_row(row),
        .col_r(col_r),
        .col_g(col_g)
    );

    initial begin
        clk_in = 0;
        forever #50 clk_in = ~clk_in;
    end

    initial begin
        #10000;
        $finish;
    end

    initial begin
        $dumpfile("tb_digi_screen.vcd");
        $dumpvars(0, digi_screen_test);
    end

endmodule
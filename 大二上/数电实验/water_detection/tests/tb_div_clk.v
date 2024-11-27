`timescale 1ns/1ps

module div_clk_test;
    
    reg clk_in; // 10MHz
    
    wire div_100;
    wire div_10;
    reg rst;

    initial begin
        clk_in = 0;

        forever #50 clk_in = ~clk_in;
    end

    div_clk div_clk_100 (
        .clk_in(clk_in),
        .rst(rst),
        .clk_out(div_100)
    );

    div_clk
    #(
        .DIVISOR(10)
    )
    div_clk_10 
    (
        .clk_in(clk_in),
        .rst(rst),
        .clk_out(div_10)
    );

    initial begin
        rst = 0;
        #10000;
        #100 rst = 1;
        #100 rst = 0;
        #10000;
        $finish;
    end
    //clk_in 10MHz
    initial begin
        $dumpfile("tb_div_clk.vcd");
        $dumpvars(0, div_clk_test);
    end

endmodule
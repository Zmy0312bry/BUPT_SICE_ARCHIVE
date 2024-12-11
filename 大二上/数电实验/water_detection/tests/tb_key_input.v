`timescale 1ns/1ps

module key_input_test;
    reg clk_in;
    reg [3:0] row;
    wire [3:0] col;
    wire [3:0] key;

    key_input uut (
        .clk(clk_in),
        .row(row),
        .col(col),
        .key(key)
    );
    initial begin
        clk_in = 0;

        forever #50 clk_in = ~clk_in;
    end

    initial begin
        row = 4'b1111;
        #120;
        row = 4'b1101;
        #5;
        row = 4'b1111;
        #5;
        row = 4'b1101;
        #70;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        row = 4'b1101;
        #100;
        row = 4'b1111;
        #300;
        #50;
        #100;
        #1000;
        
        $finish;
    end
    //clk_in 10MHz
    initial begin
        $dumpfile("tb_key_input.vcd");
        $dumpvars(0, key_input_test);
    end

endmodule
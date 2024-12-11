`timescale 1ns/1ps

module led_disp_test;
    reg clk;
    reg [3:0] key;

    wire [7:0] select;
    wire [6:0] segment7x;
    wire dp;

    led_disp led_disp_inst(
        .clk(clk),
        .key(key),
        .select(select),
        .segment7x(segment7x),
        .dp(dp)
    );

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        key = 4'b1111;
        #100 key = 4'b0001;
        #10 key = 4'b1111;
        #100 key = 4'b0010;
        #10 key = 4'b1111;
        #1000;
        $finish;
    end

    initial begin
        $dumpfile("tb_led_disp.vcd");
        $dumpvars(0, led_disp_test);
    end

endmodule
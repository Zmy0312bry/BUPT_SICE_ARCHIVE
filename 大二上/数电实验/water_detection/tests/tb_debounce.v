`timescale 1ns/1ps
module debounce_test;
    reg clk;
    reg rst;
    reg key;
    wire key_pulse;

debounce db(
    .clk(clk),
    .rst(rst),
    .key(key),
    .key_pulse(key_pulse)
);
initial begin
    $dumpfile("tb_debounce.vcd");
    $dumpvars(0, debounce_test);
end
initial begin
    clk = 0;
    rst = 0;
    forever begin
        #50 clk = ~clk;
    end
end
initial begin
    key = 0;
    #5 key = 1;
    #5 key = 0;
    #5 key = 1;
    #5 key = 0;
    #5 key = 1;
    #5 key = 0;
    #5 key = 1;
    #5 key = 0;
    #1000;
    key = 1;
    #2000;
    key = 0;
    #5000;
    $finish;
end
endmodule

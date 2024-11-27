`timescale 1ns / 1ps

module select_disp_test;

reg clk;
reg rst_n;
wire [7:0] out;
initial begin   
    $dumpfile("tb_select_disp.vcd");   
    $dumpvars(0, select_disp_test);   
end

select_disp uut(
    .clk(clk),
    .rst_n(rst_n),
    .out(out)
);

initial begin
    clk = 0;
    forever begin
        #5 clk = ~clk;
    end
end

initial begin
    rst_n = 1;
    #10000
    rst_n = 0;
    #1000
    $finish;
end

endmodule
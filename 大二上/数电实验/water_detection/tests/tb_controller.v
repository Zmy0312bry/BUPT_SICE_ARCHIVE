`timescale 1ns/1ps
module controller_test;

reg clk;
reg [31:0] number;
reg [7:0] dp_list;
reg btn0;

wire [2:0] state;

controller controller_inst(
    .clk(clk),
    .number(number),
    .dp_list(dp_list),
    .btn0(btn0),
    .state(state)
);
initial begin
    clk = 0;
    forever begin
        #5 clk = ~clk;
    end
end

initial begin
    $dumpfile("tb_controller.vcd");
    $dumpvars(0, controller_test);
end

initial begin
    number = 32'h08080706;
    btn0 = 0;
    dp_list = 8'b0001_0000;
    #10000;
    number = 32'hff020202;
    dp_list = 8'b00000001;
    #10000;
    number = 32'hffffff02;
    dp_list = 8'b00000001;
    #10000;
    btn0 = 1;
    #10000;
    btn0 = 0;
    #10000;
    $finish;
end
endmodule
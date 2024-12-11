`timescale 1ns/1ps
module tb_beep;
reg clk;
reg beep_en;
reg [2:0] state;
wire beep_out;
beep uut (
    .clk(clk),
    .beep_en(beep_en),
    .state(state),
    .beep_out(beep_out)
);
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end
initial begin
    state = 3'b000;
    beep_en = 1;
    #500;
    state = 3'b001;
    beep_en = 1;
    #500;
    state = 3'b010;
    beep_en = 1;
    #500;
    state = 3'b011;
    beep_en = 0;
    #500;
    state = 3'b011;
    beep_en = 1;
    #500;
    state = 3'b100;
    beep_en = 1;
    #500;
    state = 3'b101;
    beep_en = 1;
    #500;
    state = 3'b110;
    beep_en = 1;
    #500;
    state = 3'b111;
    beep_en = 1;
    #500;
    state = 3'b000;
    beep_en = 0;
    #500;
    $finish;
end
initial begin
        $dumpfile("tb_beep.vcd");
        $dumpvars(0, tb_beep);
end
endmodule





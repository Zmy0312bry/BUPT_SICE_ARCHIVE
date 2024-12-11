module beep(
    input clk,
    input beep_en,
    input [2:0] state,
    output beep_out
);
wire beep_out_state0,beep_out_state1,beep_out_state2,beep_out_state3,beep_out_state4,beep_out_state5;
div_clk #(.DIVISOR(12)) div_clk_beep1 (.clk_in(clk),.rst(),.clk_out(beep_out_state0));
div_clk #(.DIVISOR(10)) div_clk_beep2 (.clk_in(clk),.rst(),.clk_out(beep_out_state1));
div_clk #(.DIVISOR(8)) div_clk_beep3 (.clk_in(clk),.rst(),.clk_out(beep_out_state2));
div_clk #(.DIVISOR(6)) div_clk_beep4 (.clk_in(clk),.rst(),.clk_out(beep_out_state3));
div_clk #(.DIVISOR(4)) div_clk_beep5 (.clk_in(clk),.rst(),.clk_out(beep_out_state4));
div_clk #(.DIVISOR(2)) div_clk_beep6 (.clk_in(clk),.rst(),.clk_out(beep_out_state5));

assign beep_out = (state == 3'b000) ? 1'b0 :
                  (state == 3'b001) ? beep_out_state0 :
                  (state == 3'b010) ? beep_out_state1 :
                  (state == 3'b011) ? beep_out_state2 :
                  (state == 3'b100) ? beep_out_state3 :
                  (state == 3'b101) ? beep_out_state4 :
                  (state == 3'b110) ? beep_out_state5 :
                  (state == 3'b111) ? beep_out_state5 :
                  1'b0;

endmodule
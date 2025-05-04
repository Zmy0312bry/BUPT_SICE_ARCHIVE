module VI_V_74LS374
( 
input [7:0] d_in, 
input clk, 
input oe_n, 
output [7:0] d_out 
); 
reg [7:0] d; 
always @(posedge clk) 
begin  
d <= d_in;  
end 
assign d_out = oe_n ? d : 8'bzzzz_zzzz; 
endmodule 
module VI_IV_YiCunQi
( 
	input clk, rst_n,  
	input din,   // 串入 
	output reg [7:0] p_dout, // 并出 
	output s_dout // 串出 
); 
	always@(posedge clk) begin 
		if(!rst_n) p_dout <= 8'h00; 
		else begin 
		p_dout <= {p_dout[6:0], din}; 
		end 
	end 
assign s_dout = p_dout[7]; 
endmodule 
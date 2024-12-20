 module beep
 #(
   parameter CNT_MAX = 25'd5000000,
	parameter DO = 18'd3817,
	parameter RE = 18'd3401,
	parameter MI = 18'd3030,
	parameter FA = 18'd2865,
	parameter SO = 18'd2551,
	parameter LA = 18'd2272,
	parameter XI = 18'd2024       
 )
 (
 input wire sys_clk,
 input wire sys_rst_n,
 input is_final,
 
 output reg beep
 );
reg [24:0] cnt;
reg [2:0]  cnt_500ms;
reg [17:0] freq_cnt;
reg [17:0] freq_data;
wire [16:0] duty_data;

always@(posedge sys_clk or negedge sys_rst_n)
      if(sys_rst_n == 1'b0)
		  cnt = 25'd0;
		else if(cnt == CNT_MAX)
		  cnt = 25'd0;
		else
		  cnt = cnt + 25'd1;
		  
always@(posedge sys_clk or negedge sys_rst_n)
      if(sys_rst_n == 1'b0)
		  cnt_500ms <= 3'd0;
		else if((cnt_500ms == 3'd6) && (cnt == CNT_MAX))
		  cnt_500ms <= 3'd0;
		else if(cnt == CNT_MAX)
		  cnt_500ms <= cnt_500ms + 3'd1;
		else
		  cnt_500ms <= cnt_500ms;
		  
always@(posedge sys_clk or negedge sys_rst_n)
      if(sys_rst_n == 1'b0)
		  freq_cnt <= 18'd0;
		else if((freq_cnt == freq_data) || (cnt == CNT_MAX)) //如果cnt到达最大值，就进入下一音调频率的计数，故此音调频率清零
		  freq_cnt <= 18'd0;
		else
		  freq_cnt <= freq_cnt + 18'd1;
		  
always@(posedge sys_clk or negedge sys_rst_n)
      if(sys_rst_n == 1'b0)
		  freq_data <= DO;
		else case(cnt_500ms)
		3'd0:freq_data <= DO;
		3'd1:freq_data <= RE;
		3'd2:freq_data <= MI;
		3'd3:freq_data <= FA;
		3'd4:freq_data <= SO;
		3'd5:freq_data <= LA;
		3'd6:freq_data <= XI;
		default:freq_data <= DO;
		endcase
		
assign duty_data = freq_data >> 1;  //左移一位相当于乘以2，右移一位除2

always@(posedge sys_clk or negedge sys_rst_n)
      if(sys_rst_n == 1'b0)
		  beep <= 1'b0;
		else
		if(is_final)begin
			if(freq_cnt >= duty_data)
			  beep <= 1'b1;
			else
			  beep <= 1'b0;
		end
		  
endmodule

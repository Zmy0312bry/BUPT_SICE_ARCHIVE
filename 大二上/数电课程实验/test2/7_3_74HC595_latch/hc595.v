module hc595( 
	input sclr_n, si, sck, rck, g_n, //sclr_n 低电平有效、复位信号，si Signal_Input，sck 串行数字input，g_n 低电平有效、使能信号
	output qh_qout, // qh_qout 移位寄存器的最后一位
	output reg [7:0] shift_dffs,
	output [7:0] q
); 
//reg [7:0] shift_dffs;  // 移位寄存器
reg [7:0] storge_dffs; // latch
always @(posedge sck or negedge sclr_n) begin 
	if (~sclr_n)  shift_dffs[7:0] <= 8'h00;        // 异步复位 
	else  shift_dffs[7:0] <= {shift_dffs[6:0], si};// 将si拼接在shift_dffs后面  
end 
always @(posedge rck) begin 
	storge_dffs[7:0] <= shift_dffs[7:0];  //将数据导入latch
end
// 两个基本赋值
assign gh_qout = shift_dffs[7]; 
assign q=g_n? 8'bzzzzzzzz:storge_dffs[7:0]; 
endmodule 
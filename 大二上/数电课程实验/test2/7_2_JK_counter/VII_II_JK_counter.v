module VII_II_JK_counter(
 input wire clk, // 开发板上的系统时钟
 input wire rst_n, // 复位信号（低电平有效）
 output [7:0] seg,
 output wire [3:0] dout
);

wire clk_div;
// wire [3:0] dout;

 // 实例化时钟分频器
 clk_divider clk_div_inst (
 .clk_in(clk),
 .rst_n(rst_n),
 .clk_out(clk_div)
 );
 
 // 实例化计数器
 counter counter_inst (
 .clk_div(clk_div),
 .dout(dout)
 );
 
 seven_segment_decoder uut(
.digit_in(dout),
.seg_out(seg)
 
 );
 
 
endmodule
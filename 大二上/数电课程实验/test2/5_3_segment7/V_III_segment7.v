module V_III_segment7(
    input [2:0] bcd,    //BCD码
    output [8:0] seg   //输出信号
	 );·
    seven_segment_decoder u1(  // 调用
        .in(bcd),
        .seg_led(seg)
    ); 
endmodule

module binary_bcd(
    input [4:0] bin,       // 5位二进制输入
    output reg [3:0] bcd_tens, // BCD十位
    output reg [3:0] bcd_ones  // BCD个位
);
   // 临时变量，用于存储当前处理的二进制数
   reg [4:0] temp_bin;

	always @(bin) begin
		 // 初始化BCD寄存器
		 bcd_tens = 4'b0000;
		 bcd_ones = 4'b0000;
		 
		 temp_bin = bin;
		 // 处理十位
		 bcd_tens = temp_bin/10;       // BCD十位加1
		 temp_bin = temp_bin - bcd_tens * 10;
		 // 处理个位
		 bcd_ones = temp_bin; // 剩余的部分就是BCD个位
end

endmodule

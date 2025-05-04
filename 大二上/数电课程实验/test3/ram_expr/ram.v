module ram(   
    input clk,    // 时钟信号
    // input rst,    // 复位信号
    input we,     // 写使能信号   
    input [3:0] addr, // 地址输入
    input [3:0] data_in, // 数据输入 
    output [3:0] data_out     // 数据输出 
);   
    // 4 * 16 存储单元阵列 
    reg [3:0] ram[15:0];
	 initial begin
		ram[0] = 4'h0;
		ram[1] = 4'h1;
		ram[2] = 4'h2;
		ram[3] = 4'h3;
		ram[4] = 4'h4;
		ram[5] = 4'h5;
		ram[6] = 4'h6;
		ram[7] = 4'h7;
		ram[8] = 4'h8;
		ram[9] = 4'h9;
		ram[10] = 4'ha;
		ram[11] = 4'hb;
		ram[12] = 4'hc;
		ram[13] = 4'hd;
		ram[14] = 4'he;
		ram[15] = 4'hf;
	 end
    always @(posedge clk) begin  
        if (we) begin
            ram[addr] <= data_in;
        end
    end   
    // 读取操作，data_out输出addr处存储单元中的值 
    assign data_out = ram[addr];
endmodule 
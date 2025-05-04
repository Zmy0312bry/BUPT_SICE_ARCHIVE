module ram256x8(   
    input clk,    // 时钟信号
    // input rst,    // 复位信号
    input we,     // 写使能信号   
    input [7:0] addr, // 地址输入
    input [3:0] data_in, // 数据输入 
    output [3:0] data_out     // 数据输出 
);   
    // 256 * 4 存储单元阵列 
    reg [3:0] ram[255:0];
    always @(posedge clk) begin  
        if (we) begin
            ram[addr] <= data_in;
        end
    end   
    // 读取操作，data_out输出addr处存储单元中的值 
    assign data_out = ram[addr];
endmodule 
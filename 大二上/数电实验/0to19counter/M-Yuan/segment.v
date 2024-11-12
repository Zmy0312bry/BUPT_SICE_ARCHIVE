module segment(
    input [7:0] bcd_num,     // 8位 BCD 数字，低四位为个位，高四位为十位
    input clk,               // 时钟信号
    output reg [1:0] cat,    // 位选信号，用于选择显示的数码管
    output reg [7:0] signal  // 7段显示信号
);

// 初始化 cat 为 2'b01，用于初始选择个位
initial begin
    cat = 2'b01;
    signal = 8'b00000000;  // 给 seg 一个初始值
end

// 在时钟上升沿切换 cat，并根据 cat 显示对应的数码管
always @(posedge clk) begin
    // 使用移位操作来交替切换 cat
    cat <= {cat[0], cat[1]}; // 将 cat 的值在 2'b01 和 2'b10 之间切换

    // 根据 cat 来选择不同的数码管并输出相应的 BCD 信号
    if (cat == 2'b01) begin
        // 显示个位，低四位 bcd_num[3:0]
        case (bcd_num[3:0])
           4'b0000: signal = 8'b1111_1100; // 显示 "0"
			  4'b0001: signal = 8'b0110_0000; // 显示 "1"
			  4'b0010: signal = 8'b1101_1010; // 显示 "2"
			  4'b0011: signal = 8'b1111_0010; // 显示 "3"
			  4'b0100: signal = 8'b0110_0110; // 显示 "4"
			  4'b0101: signal = 8'b1011_0110; // 显示 "5"
			  4'b0110: signal = 8'b1011_1110; // 显示 "6"
			  4'b0111: signal = 8'b1110_0000; // 显示 "7"
			  4'b1000: signal = 8'b1111_1110; // 显示 "8"
			  4'b1001: signal = 8'b1111_0110; // 显示 "9"
			  default: signal = 8'b0000_0000; // 默认全部熄灭
        endcase
    end else if (cat == 2'b10) begin
        // 显示十位，高四位 bcd_num[7:4]
        case (bcd_num[7:4])
           4'b0000: signal = 8'b1111_1100; // 显示 "0"
			  4'b0001: signal = 8'b0110_0000; // 显示 "1"
			  4'b0010: signal = 8'b1101_1010; // 显示 "2"
			  4'b0011: signal = 8'b1111_0010; // 显示 "3"
			  4'b0100: signal = 8'b0110_0110; // 显示 "4"
			  4'b0101: signal = 8'b1011_0110; // 显示 "5"
			  4'b0110: signal = 8'b1011_1110; // 显示 "6"
			  4'b0111: signal = 8'b1110_0000; // 显示 "7"
			  4'b1000: signal = 8'b1111_1110; // 显示 "8"
			  4'b1001: signal = 8'b1111_0110; // 显示 "9"
			  default: signal = 8'b0000_0000; // 默认全部熄灭
        endcase
    end
end

endmodule

			
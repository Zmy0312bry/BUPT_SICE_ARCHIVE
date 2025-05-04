module clk_divider #(
    parameter N = 12000000 // 分频系数
)(
    input wire clk_in,   // 输入时钟
    input wire rst_n,    // 低电平有效复位信号
    output reg clk_out   // 输出分频后的时钟
);
    // 动态计算计数器位宽
    localparam CNT_WIDTH = $clog2(N/2);
    reg [CNT_WIDTH-1:0] counter; // 计数器
    initial begin
        counter = 0;
        clk_out = 0;
    end
    // 计数器逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) 
            counter <= 0;
        else if (counter == (N/2 - 1))
            counter <= 0;
        else
            counter <= counter + 1;
    end

    // 输出时钟翻转逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            clk_out <= 0;
        else if (counter == (N/2 - 1))
            clk_out <= ~clk_out;
    end
endmodule

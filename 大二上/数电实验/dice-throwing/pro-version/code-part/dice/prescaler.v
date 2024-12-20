module prescaler #(
    parameter DIVIDE_BY = 1000      // 分频因子，默认分频为2
)(
    input wire clk_in,           // 输入时钟信号
    input wire rst,              // 复位信号
    output reg clk_out           // 输出分频后的时钟信号
);

    reg [31:0] counter = 0;      // 32位计数器，用于计数输入时钟周期

    always @(posedge clk_in or negedge rst) begin
        if (!rst) begin
            counter <= 0;        // 如果复位信号为高电平，清零计数器
            clk_out <= 0;        // 复位时，将输出时钟清零
        end else begin
            if (counter == DIVIDE_BY- 1 ) begin
                counter <= 0;    // 每到达分频周期时，计数器清零
                clk_out <= ~clk_out; // 翻转输出时钟
            end else begin
                counter <= counter + 1; // 否则，计数器自增
            end
        end
    end

endmodule

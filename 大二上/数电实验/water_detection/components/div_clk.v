module div_clk #(
    parameter DIVISOR = 100 // 默认100，即10MHz/100=100KHz
)(
    input wire clk_in,      // 10MHz
    input wire rst,         // 复位
    output reg clk_out      // 输出分频结果
);

    reg [9:0] counter;     // 计数器，最高支持分频2^32
    initial begin
        clk_out = 0;
        counter = 0;
    end
    always @(negedge clk_in or posedge rst) begin
        if (rst) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (counter == (DIVISOR/2 - 1)) begin
                clk_out <= ~clk_out;
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
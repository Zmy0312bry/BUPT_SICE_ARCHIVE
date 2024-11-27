module select_disp (    //选位信号
    input wire clk,       // Input clock
    input wire rst_n,     // Active low reset
    output reg [7:0] out  // 8-bit output
);

initial begin
    out = 8'b01111_111;    // Initialize output to 1
end

always @(negedge clk) begin
    if (!rst_n) begin
        out <= 8'b01111_111;      // Reset output to 0
    end else begin
        out <= {out[6:0], out[7]}; // Shift output left by 1
    end
end

endmodule
module debounce(
    input clk,
    input rst,
    input key,
    output reg key_pulse
);
    reg [3:0] cnt;
    reg flag ;

initial begin
    cnt <= 4'b0000;
    key_pulse <= 1'b0;
    flag = 1'b0;
end

always @(posedge clk) begin
    if (rst) begin
        cnt <= 4'b0000;
        key_pulse <= 1'b0;
        flag = 1'b0;
    end else if (key) begin
        if (cnt == 4'b1111 && flag == 1'b0 ) begin
            key_pulse = 1'b1;
            flag = 1'b1;
            cnt = 4'b0000;
        end else if (cnt != 4'b1111) begin
            cnt = cnt + 4'b0001;
            key_pulse = 1'b0;
        end else begin
            key_pulse = 1'b0;
            flag = 1'b1;
        end
        
    end else if (!key) begin
        flag = 0;
    end
end

endmodule

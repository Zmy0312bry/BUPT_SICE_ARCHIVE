module controller(
    input wire clk,
    input [7:0] number,
    input wire btn0,
    output reg [2:0] state
);
    wire key;
    reg [6:0] integer_value;
    reg mode; // 0: 正常模式，1: 
initial begin
    mode = 0;
    integer_value = 7'b000_0000;
end
    // 处理按钮切换模式
    debounce dbs (
        .clk(clk),
        .rst(1'b0),
        .key(btn0),
        .key_pulse(key)
    );

    always@(posedge key) begin
        mode =~mode;
    end

    // 处理number和dp_list，计算state
    always @(*) begin
        integer_value =number[7:4] * 10+number[3:0];

        // 根据模式设置state
        if (mode && integer_value >= 14) begin
            state = 3'b111;
        end else begin
            if (integer_value < 6) begin
                state = 3'b000;
            end else if (integer_value < 8) begin
                state = 3'b001;
            end else if (integer_value < 10) begin
                state = 3'b010;
            end else if (integer_value < 12) begin
                state = 3'b011;
            end else if (integer_value < 13) begin
                state = 3'b100;
            end else if (integer_value < 14) begin
                state = 3'b101;
            end else begin
                state = 3'b110;
            end
        end
    end

endmodule
module controller(
    input wire clk,
    input [31:0] number,
    input [7:0] dp_list,
    input wire btn0,
    output reg [2:0] state
);

    reg [31:0] actual_number;
    reg [3:0] bcd_digit [7:0];
    integer i;
    integer dp_position;
    integer integer_value;
    wire key;
    reg mode; // 0: 正常模式，1: 
initial begin
    mode = 0;
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
        // 初始化
        actual_number = number;
        dp_position = 8; // 默认为无小数点位置

        // 忽略高位无意义的FF
        for (i = 7; i >= 0; i = i - 1) begin
            if (number[4*i +: 4] == 4'hF) begin
                actual_number[4*i +: 4] = 4'h0;
            end
        end

        // 提取BCD位
        for (i = 0; i < 8; i = i + 1) begin
            bcd_digit[i] = actual_number[4*(7 - i) +: 4];
        end

        // 找到小数点位置
        for (i = 0; i < 8; i = i + 1) begin
            if (dp_list[i]) begin
                dp_position = i;
            end
        end

        // 计算整数部分的值
        integer_value = 0;
        for (i = dp_position; i < 8; i = i + 1) begin
            integer_value = integer_value * 10 + bcd_digit[i];
        end

        // 根据模式设置state
        if (mode && integer_value > 14) begin
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
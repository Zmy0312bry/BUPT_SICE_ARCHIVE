// RAM模块 - 用于缓存从ARM传入的784位图像数据
// 输入：串行数据流（每个时钟周期接收1位）
// 输出：784位并行数据供MNIST模型使用

module ram(
    input wire clk,
    input wire rst,
    input wire data_in,           // 串行数据输入
    input wire write_enable,      // 写使能信号
    output reg [783:0] image_out, // 784位并行输出
    output reg data_ready         // 数据准备好信号
);

    reg [9:0] write_counter;      // 写入计数器 (0-783)

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            image_out <= 784'b0;
            write_counter <= 10'd0;
            data_ready <= 1'b0;
        end else begin
            if (write_enable) begin
                // 串行写入数据
                image_out[write_counter] <= data_in;

                if (write_counter == 10'd783) begin
                    // 接收完784位数据
                    write_counter <= 10'd0;
                    data_ready <= 1'b1;
                end else begin
                    write_counter <= write_counter + 1'b1;
                    data_ready <= 1'b0;
                end
            end else begin
                // 不写入时保持数据准备好状态
                if (write_counter == 10'd0) begin
                    data_ready <= 1'b0;
                end
            end
        end
    end

endmodule

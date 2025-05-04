module wave_dac (
    input wire clk,           // 时钟信号
    input wire rst_n,         // 异步复位信号，低电平有效
    output reg [7:0] dac_out  // 8位并行输出到DAC
);

// 参数定义
localparam MAX_COUNT = 255; // 计数器的最大值，对应于8位DAC的最大值
localparam HIGH_COUNT = 128; // 高电平持续的时间（占空比），可调整
localparam LOW_COUNT = MAX_COUNT - HIGH_COUNT + 1; // 低电平持续的时间

// 内部变量
reg [7:0] counter = 0; // 计数器
reg state = 0; // 矩形波状态，0表示低电平，1表示高电平

// 时钟分频和矩形波生成
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 异步复位
        counter <= 0;
        state <= 0;
        dac_out <= 0;
    end else begin
        // 计数器递增
        counter <= counter + 1'b1;

        // 根据计数器生成矩形波
        if (counter < HIGH_COUNT) begin
            state <= 1; // 高电平
            dac_out <= MAX_COUNT; // 8位DAC输出高电平的最大值
        end else if (counter < (HIGH_COUNT + LOW_COUNT)) begin
            state <= 0; // 低电平
            dac_out <= 0; // 8位DAC输出低电平
        end else begin
            counter <= 0; // 计数器重置
        end
    end
end

endmodule

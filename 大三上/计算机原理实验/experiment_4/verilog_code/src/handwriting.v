// 手写数字识别顶层模块
// 接口说明：
//   - clk: 时钟输入（由ARM提供）
//   - rst: 复位信号（高电平有效）
//   - data_in: 串行数据输入（每个时钟周期1位，共需要784个时钟周期）
//   - busy: 忙碌信号（高电平表示正在接收数据或计算中）
//   - digit_out: 识别结果输出（4位，表示0-9）
//   - result_valid: 结果有效信号（高电平表示digit_out有效）

module handwriting(
    input wire clk,
    input wire rst,
    input wire data_in,
    output wire busy,
    output wire [3:0] digit_out,
    output wire result_valid
);

    // 状态机定义
    localparam IDLE = 3'd0;           // 空闲状态
    localparam RECEIVING = 3'd1;      // 接收数据状态
    localparam COMPUTING = 3'd2;      // 计算状态
    localparam DONE = 3'd3;           // 完成状态

    reg [2:0] state;
    
    // RAM模块信号
    reg ram_write_enable;
    wire [783:0] image_data;
    wire ram_data_ready;
    
    // MNIST模型信号
    reg mnist_start;
    wire mnist_valid;
    wire [3:0] mnist_digit_out;
    
    // 输出寄存器
    reg busy_reg;
    reg [3:0] digit_out_reg;
    reg result_valid_reg;

    // 输出赋值
    assign busy = busy_reg;
    assign digit_out = digit_out_reg;
    assign result_valid = result_valid_reg;

    // 实例化RAM模块
    ram ram_inst (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .write_enable(ram_write_enable),
        .image_out(image_data),
        .data_ready(ram_data_ready)
    );

    // 实例化MNIST模型
    mnist_model mnist_inst (
        .clk(clk),
        .rst(rst),
        .image_in(image_data),
        .start(mnist_start),
        .digit_out(mnist_digit_out),
        .valid(mnist_valid)
    );

    // 主状态机
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            ram_write_enable <= 1'b1;  // 复位后立即准备好接收，确保第一个时钟就能写入
            mnist_start <= 1'b0;
            busy_reg <= 1'b0;
            digit_out_reg <= 4'd0;
            result_valid_reg <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    busy_reg <= 1'b0;
                    result_valid_reg <= 1'b0;
                    mnist_start <= 1'b0;
                    ram_write_enable <= 1'b1;  // 保持写使能，准备接收第一个数据位
                    
                    // ARM复位后第一个时钟上升沿进入接收状态
                    // write_enable已经在IDLE时就是1，所以第一个时钟就能写入数据
                    state <= RECEIVING;
                end

                RECEIVING: begin
                    // 拉高busy信号
                    busy_reg <= 1'b1;
                    ram_write_enable <= 1'b1;  // 继续保持写使能
                    
                    // 等待RAM接收完784位数据
                    if (ram_data_ready) begin
                        ram_write_enable <= 1'b0;
                        state <= COMPUTING;
                        mnist_start <= 1'b1;
                    end
                end

                COMPUTING: begin
                    mnist_start <= 1'b0;  // start信号只需要一个时钟周期
                    busy_reg <= 1'b1;     // 保持busy信号
                    
                    // 等待MNIST计算完成
                    if (mnist_valid) begin
                        digit_out_reg <= mnist_digit_out;
                        result_valid_reg <= 1'b1;
                        busy_reg <= 1'b0;
                        state <= DONE;
                    end
                end

                DONE: begin
                    // 保持结果有效，busy信号为低
                    result_valid_reg <= 1'b1;
                    busy_reg <= 1'b0;
                    
                    // 保持DONE状态，直到外部复位
                    // ARM读取结果后会停止时钟，下次启动时会复位
                    // 如果不复位而是继续时钟，则保持在DONE状态
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
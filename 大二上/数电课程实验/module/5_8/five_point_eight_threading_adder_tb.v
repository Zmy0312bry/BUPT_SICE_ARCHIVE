/*
 * @Author: zhao-leo 18055219130@163.com
 * @Date: 2024-10-19 00:41:53
 * @LastEditors: zhao-leo 18055219130@163.com
 * @LastEditTime: 2024-10-19 00:44:09
 * @FilePath: \module\5_7\five_point_eight_threading_adder_tb.v
 */
module five_point_eight_threading_adder_tb;
    // 输入信号
    reg [3:0] a, b;
    reg cin;
    // 输出信号
    wire [3:0] sum;
    wire cout;

    // 实例化被测试的模块
    five_point_eight_threading_adder uut (
        .A(a),
        .B(b),
        .Cin(cin),
        .S(sum),
        .Cout(cout)
    );
    initial begin
        $dumpfile("5_8_tb.vcd"); //生成的vcd文件名称
        $dumpvars(0, five_point_eight_threading_adder_tb); //tb模块名称
    end
    initial begin
        // 初始化输入信号
        a = 4'b0000; b = 4'b0000; cin = 1'b0;
        #10; // 等待 10 个时间单位

        // 测试用例 1
        a = 4'b0001; b = 4'b0010; cin = 1'b0;
        #10; // 等待 10 个时间单位

        // 测试用例 2
        a = 4'b0101; b = 4'b0011; cin = 1'b1;
        #10; // 等待 10 个时间单位

        // 测试用例 3
        a = 4'b1111; b = 4'b1111; cin = 1'b1;
        #10; // 等待 10 个时间单位

        // 测试用例 4
        a = 4'b1010; b = 4'b0101; cin = 1'b0;
        #10; // 等待 10 个时间单位

        // 结束仿真
        $finish;
    end

    initial begin
        // 监视信号变化
        $monitor("Time = %0d, a = %b, b = %b, cin = %b, sum = %b, cout = %b", $time, a, b, cin, sum, cout);
    end
endmodule
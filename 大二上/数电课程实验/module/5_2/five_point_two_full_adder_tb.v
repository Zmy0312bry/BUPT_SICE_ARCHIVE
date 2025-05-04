/*
 * @Author: zhao-leo 18055219130@163.com
 * @Date: 2024-10-21 19:05:39
 * @LastEditors: zhao-leo 18055219130@163.com
 * @LastEditTime: 2024-10-21 19:13:49
 * @FilePath: \module\5_2\five_point_two_full_adder_tb.v
 */

module five_point_two_full_adder_tb;
    // 输入信号
    reg  a, b;
    reg cin;
    // 输出信号
    wire sum;
    wire cout;

    // 实例化被测试的模块
    five_point_two_full_adder u1 (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );
    initial begin
        $dumpfile("5_2_tb.vcd"); //生成的vcd文件名称
        $dumpvars(0, five_point_two_full_adder_tb); //tb模块名称
    end
    initial begin
        // 初始化输入信号
        a = 1'b0; b = 1'b0; cin = 1'b0;
        #10; // 等待 10 个时间单位

        // 测试用例 1
        a = 1'b0; b = 1'b1; cin = 1'b0;
        #10; // 等待 10 个时间单位

        // 测试用例 2
        a = 1'b1; b = 1'b1; cin = 1'b0;
        #10; // 等待 10 个时间单位

        // 测试用例 3
        a = 1'b1; b = 1'b0; cin = 1'b0;
        #10; // 等待 10 个时间单位

        // 测试用例 4
        a = 1'b1; b = 1'b0; cin = 1'b1;
        #10; // 等待 10 个时间单位

        // 测试用例 5
        a = 1'b1; b = 1'b1; cin = 1'b1;
        #10; // 等待 10 个时间单位

        // 结束仿真
        $finish;
    end

    initial begin
        // 监视信号变化
        $monitor("Time = %0d, a = %b, b = %b, cin = %b, sum = %b, cout = %b", $time, a, b, cin, sum, cout);
    end
endmodule
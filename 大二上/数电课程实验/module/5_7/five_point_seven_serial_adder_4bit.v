/*
 * @Author: zhao-leo 18055219130@163.com
 * @Date: 2024-10-18 22:01:38
 * @LastEditors: zhao-leo 18055219130@163.com
 * @LastEditTime: 2024-10-18 22:06:53
 * @FilePath: \module\5_7\five_point_seven_serial_adder_4bit.v
 */
module five_point_seven_serial_adder_4bit(
    input [3:0] a, b, // 两组 4 位加数
    input cin, // 低位来的进位
    output [3:0] sum, // 加法运算的结果
    output cout // 最高位的进位
);
    wire [3:0] c; // 进位线
    full_adder
    fa0(.a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .cout(c[0]));
    full_adder 
    fa1(.a(a[1]), .b(b[1]), .cin(c[0]), .sum(sum[1]), .cout(c[1]));
    full_adder
    fa2(.a(a[2]), .b(b[2]), .cin(c[1]), .sum(sum[2]), .cout(c[2]));
    full_adder 
    fa3(.a(a[3]), .b(b[3]), .cin(c[2]), .sum(sum[3]), .cout(cout));
endmodule
module full_adder(
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule
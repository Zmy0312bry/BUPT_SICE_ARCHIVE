/*
 * @Author: zhao-leo 18055219130@163.com
 * @Date: 2024-10-21 19:03:48
 * @LastEditors: zhao-leo 18055219130@163.com
 * @LastEditTime: 2024-10-21 19:05:20
 * @FilePath: \project\5_2\full_adder.v
 */
module full_adder(a,b,cin,sum,cout);
    input a;//加数
    input b;//被加数
    input cin;//低位来的进位项
    output sum; //求得的和
    output cout; //向高位的进位
    wire [7:0]out;
    _five_point_two_74LS138 u1 (
    .G1(1),
    .G2A(0),
    .G2B(0),
    .address({a,b,cin}),
    .outputs(out)
    );
    assign sum = !( out[1] & out[2] & out[4] & out[7] );
    assign cout =!( out[3] & out[5] & out[6] & out[7] );
endmodule
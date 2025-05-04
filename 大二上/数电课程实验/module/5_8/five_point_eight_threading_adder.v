/*
 * @Author: zhao-leo 18055219130@163.com
 * @Date: 2024-10-18 22:08:23
 * @LastEditors: zhao-leo 18055219130@163.com
 * @LastEditTime: 2024-10-19 00:57:47
 * @FilePath: \module\5_8\five_point_eight_threading_adder.v
 */
module five_point_eight_threading_adder(
 input [3:0]A, B,
 input Cin,
 output [3:0] S,
 output Cout
);
    wire [3:0] Ci;
    assign Ci[0] = Cin;
    assign Ci[1] = (A[0] & B[0]) | ((A[0]^B[0]) & Ci[0]);
    //assign Ci[2] = (A[1] & B[1]) | ((A[1]^B[1]) & Ci[1]);
    assign Ci[2] = (A[1] & B[1]) | ((A[1]^B[1]) & ((A[0] & B[0]) | ((A[0]^B[0]) & Ci[0])));
    //assign Ci[3] = (A[2] & B[2]) | ((A[2]^B[2]) & Ci[2]); 
    assign Ci[3] = (A[2] & B[2]) | ((A[2]^B[2]) & ((A[1] & B[1]) | ((A[1]^B[1]) & ((A[0] & B[0]) | ((A[0]^B[0]) & Ci[0])))));
    //assign Cout = (A[3] & B[3]) | ((A[3]^B[3]) & Ci[3]);
    assign Cout = (A[3] & B[3]) | ((A[3]^B[3]) & ((A[2] & B[2]) | ((A[2]^B[2]) & ((A[1] & B[1]) | ((A[1]^B[1]) & ((A[0] & B[0]) | ((A[0]^B[0]) & Ci[0])))))));
    assign S = A^B^Ci;
endmodule
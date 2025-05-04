module full_adder(a,b,cin,sum,cout);
    input a;        //加数
    input b;        //被加数
    input cin;      //低位来的进位项
    output sum;     //求得的和
    output cout;    //向高位的进位
    wire [7:0]out;  //输出
    V_II_74LS138 u1 (
		 .G1(1),
		 .G2A(0),
		 .G2B(0),
		 .address({a,b,cin}),
		 .outputs(out)
    );
    assign sum = !( out[1] & out[2] & out[4] & out[7] );  //1，2，4，7与非（奇数个1）
    assign cout =!( out[3] & out[5] & out[6] & out[7] );  //3，5，6，7与非（进位信号）
endmodule
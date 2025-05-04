module tri_state_buffer(input wire a, input wire enable, output wire y);
// 当 enable 为 1 时，y 的值为 a，否则 y 为高阻态（'z'）
assign y = enable ? a : 1'bz;
endmodule
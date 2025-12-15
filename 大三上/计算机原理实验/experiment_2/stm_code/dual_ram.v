module dual_ram(
    input clka,    // PIN_54(PF6)
    input clkb,    // PIN_53(PF14)

    // input ena,     // PIN_69(PF1)
    // input enb,     // PIN_68(PF9)

    input wea,     // PIN_71(PF0)
    input web,     // PIN_70(PF8)

    input  addra,   // PIN_58(PF7)
    input  addrb,   // PIN_55(PF15)

    input [1:0] data_i_a,      // data_i_a[0] PIN_60(PF4) data_i_a[1] PIN_52(PF5)
    input [1:0] data_i_b,      // data_i_b[0] PIN_59(PF12) data_i_b[1] PIN_51(PF13)

    output reg [1:0] data_o_a, // data_o_a[0] PIN_67(PF2) data_o_a[1] PIN_65(PF3)
    output reg [1:0] data_o_b  // data_o_b[0] PIN_66(PF10) data_o_b[1] PIN_64(PF11)
);
reg [1:0] RAMA [1:0];         //DATAWIDTH = 16, DEPTH = 256 = 2^8
reg [1:0] RAMB [1:0];         //DATAWIDTH = 16, DEPTH = 256 = 2^8

always @(posedge clka) begin
    // if(ena) begin
        if(wea) begin
            RAMA[addra] <= data_i_a;
        end
        data_o_a <= RAMA[addra];
    // end
end

always @(posedge clkb) begin
    // if(enb) begin
        if(web) begin
            RAMB[addrb] <= data_i_b;
        end
        data_o_b <= RAMB[addrb];
    // end
end
endmodule

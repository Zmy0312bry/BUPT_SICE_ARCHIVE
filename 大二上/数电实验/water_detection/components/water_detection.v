module water_detection(
    input wire clk,
    input btn7,
    input btn0,
    input [3:0] row_in,
    output [3:0] col,
    output [6:0] segment7,
    output [7:0] row,
    output [7:0] green_led,
    output [7:0] red_led,
    output [7:0] select,
    output beep,
    output dp
);
    wire [3:0] key;
    wire [3:0] value;
    wire [31:0] number;
    wire [7:0] dp_list;
    wire [2:0] state;


    wire beeper;
    

key_input key_input1(
    .clk(clk),
    .row(row_in),
    .col(col),
    .key(key)
);
kv_map kv_map1(
    .key(key),
    .value(value)
);
led_disp led_disp1(
    .clk(clk),
    .key(value),
    .dp(dp),
    .select(select),
    .segment7x(segment7),
    .dp_list(dp_list),
    .number(number)
);
controller controller1(
    .clk(clk),
    .number(number),
    .dp_list(dp_list),
    .btn0(btn0),
    .state(state)
);
led_matrix led_matrix1(
    .clk(clk),
    .state(state),
    .btn7(btn7),
    .red_led(red_led),
    .green_led(green_led),
    .row(row),
    .beeper(beeper)
);
beep beep1(
    .clk(clk),
    .beep_en(beeper),
    .state(state),
    .beep_out(beep)
);
endmodule

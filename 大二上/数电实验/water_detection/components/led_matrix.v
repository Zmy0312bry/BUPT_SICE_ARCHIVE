module led_matrix(//在8x8的led矩阵上显示动画，同时发出蜂鸣器声音，包含七个水位挡位，和一位按钮控制动画状态
    input clk,
    input [2:0] state,
    input btn7,
    output [7:0] red_led,
    output [7:0] green_led,
    output [7:0] row,
    output reg beeper,
    output reg [1:0] Anime_state

);
    wire clk_div_r2;
    wire clk_low;
    wire clk_middle;
    wire clk_high;
    wire key_pulse;

    div_clk #(
        .DIVISOR(1000)
    )
    div_clk_low (
        .clk_in(clk),
        .rst(),
        .clk_out(clk_low)
    );

    debounce dbsa(
        .clk(clk),
        .rst(),
        .key(btn7),
        .key_pulse(key_pulse)
    );
    div_clk #(
        .DIVISOR(500)
    )
    div_clk_mid (
        .clk_in(clk),
        .rst(),
        .clk_out(clk_middle)
    );

    div_clk #(
        .DIVISOR(250)
    )
    div_clk_high (
        .clk_in(clk),
        .rst(),
        .clk_out(clk_high)
    );

    div_clk #(
        .DIVISOR(500)
    ) div_clk_2Hz (
        .clk_in(clk),
        .rst(),
        .clk_out(clk_div_r2)
    );

    reg [63:0] r_led;
    reg [63:0] g_led;


    initial begin
        beeper = 1'b0;
        Anime_state = 2'b00;
        r_led = 0;
        g_led = 0;
    end
    always@(posedge key_pulse) begin
        if (Anime_state == 2'b10)
            Anime_state = 2'b00;
        else
            Anime_state = Anime_state + 1;
    end

    digi_screen digi_screen_red (
        .PICTURE_G(g_led),
        .PICTURE_R(r_led),
        .clk(clk),
        .row(row),
        .col_r(red_led),
        .col_g(green_led)
    );

    always@(negedge clk)begin
        case(state)
            3'b000:begin g_led =64'hffff000000000000;r_led = 64'h0000000000000000; beeper = 1'b0;end
            3'b001:begin g_led =64'hffffff0000000000;r_led = 64'hffffff0000000000; beeper = 1'b1;end
            3'b010:begin g_led =64'hffffffff00000000;r_led = 64'hffffffff00000000; beeper = 1'b1;end
            3'b011:begin g_led =64'hffffffffff000000;r_led = 64'hffffffffff000000; beeper = 1'b1;end
            3'b100:begin g_led =64'h0000000000000000;r_led = 64'hffffffffffff0000; beeper = 1'b1;end
            3'b101:begin g_led =64'h0000000000000000;r_led = 64'hffffffffffffff00; beeper = 1'b1;end
            3'b110:begin 
                case(clk_div_r2)
                1'b0:begin g_led =64'h0000000000000000;r_led = 64'h0000000000000000; end
                1'b1:begin g_led =64'h0000000000000000;r_led = 64'hffffffffffffffff; end
                endcase
                beeper = 1'b1;
                end
            3'b111:begin
                case(Anime_state)
                2'b00:begin 
                case(clk_low)
                    1'b0:begin g_led =64'h0000000000000000;r_led = 64'ha4e4ffe4e4bf1e3f; end
                    1'b1:begin g_led =64'h0000000000000000;r_led = 64'hb1eae4eaf1bf1e3f; end
                endcase
                beeper = 1'b1;
                end
                2'b01:begin
                case(clk_middle)
                    1'b0:begin g_led =64'h0000000000000000;r_led = 64'ha4e4ffe4e4bf1e3f; end
                    1'b1:begin g_led =64'h0000000000000000;r_led = 64'hb1eae4eaf1bf1e3f; end
                endcase
                beeper = 1'b1;
                end
                2'b10:begin
                case(clk_high)
                    1'b0:begin g_led =64'h0000000000000000;r_led = 64'ha4e4ffe4e4bf1e3f; end
                    1'b1:begin g_led =64'h0000000000000000;r_led = 64'hb1eae4eaf1bf1e3f; end
                endcase
                beeper = 1'b1;
                end
                endcase
             end
        endcase
    end          
endmodule

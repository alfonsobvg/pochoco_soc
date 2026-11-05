`timescale 1ns/1ps

module game_post_synth_tb;

    reg clk = 0;
    reg rst_ni = 0;
    reg [3:0] buttons = 0;

    wire [3:0] leds;
    wire spi_miso;

    wire seg1_a, seg1_b, seg1_c, seg1_d;
    wire seg1_e, seg1_f, seg1_g;
    wire seg2_a, seg2_b, seg2_c, seg2_d;
    wire seg2_e, seg2_f, seg2_g;

    always #50 clk = ~clk;

    asic_top dut (
        .clk(clk),
        .rst_ni(rst_ni),
        .buttons(buttons),
        .leds(leds),

        .seg1_a(seg1_a), .seg1_b(seg1_b),
        .seg1_c(seg1_c), .seg1_d(seg1_d),
        .seg1_e(seg1_e), .seg1_f(seg1_f),
        .seg1_g(seg1_g),

        .seg2_a(seg2_a), .seg2_b(seg2_b),
        .seg2_c(seg2_c), .seg2_d(seg2_d),
        .seg2_e(seg2_e), .seg2_f(seg2_f),
        .seg2_g(seg2_g),

        .spi_sclk(1'b0),
        .spi_mosi(1'b0),
        .spi_cs_n(1'b1),
        .spi_miso(spi_miso)
    );

    initial begin
        $dumpfile("tb/game_post_synth.vcd");
        $dumpvars(0, game_post_synth_tb);

        $display("=== POST-SYNTHESIS TEST ===");

        repeat (5) @(negedge clk);
        rst_ni = 1;

        repeat (100) @(negedge clk);

        buttons = 4'b0001;
        repeat (30) @(negedge clk);
        buttons = 0;

        repeat (1000) @(negedge clk);

        if (leds !== 4'b1111)
            $fatal(1, "FAIL: LEDs = %b, esperado 1111", leds);

        $display("PASS: LEDs = %b", leds);
        $display("=== POST-SYNTHESIS TEST PASSED ===");

        $finish;
    end

endmodule

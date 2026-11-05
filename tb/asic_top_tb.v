`timescale 1ns/1ps

module asic_top_tb;

    reg clk = 0;
    reg rst_ni = 0;
    reg [3:0] buttons = 0;

    wire [3:0] leds;

    wire seg1_a, seg1_b, seg1_c, seg1_d;
    wire seg1_e, seg1_f, seg1_g;

    wire seg2_a, seg2_b, seg2_c, seg2_d;
    wire seg2_e, seg2_f, seg2_g;

    wire spi_miso;

    // 10 MHz: periodo de 100 ns.
    always #50 clk = ~clk;

    asic_top dut (
        .clk(clk),
        .rst_ni(rst_ni),
        .buttons(buttons),
        .leds(leds),

        .seg1_a(seg1_a),
        .seg1_b(seg1_b),
        .seg1_c(seg1_c),
        .seg1_d(seg1_d),
        .seg1_e(seg1_e),
        .seg1_f(seg1_f),
        .seg1_g(seg1_g),

        .seg2_a(seg2_a),
        .seg2_b(seg2_b),
        .seg2_c(seg2_c),
        .seg2_d(seg2_d),
        .seg2_e(seg2_e),
        .seg2_f(seg2_f),
        .seg2_g(seg2_g),

        .spi_sclk(1'b0),
        .spi_mosi(1'b0),
        .spi_cs_n(1'b1),
        .spi_miso(spi_miso)
    );

    initial begin
        $dumpfile("tb/asic_top.vcd");
        $dumpvars(0, asic_top_tb);

        $display("Iniciando simulacion");

        // Mantener reset durante varios ciclos.
        repeat (5) @(negedge clk);
        rst_ni = 1;

        // Observar ejecucion inicial.
        repeat (1000) @(negedge clk);

        $display("LEDs iniciales: %b", leds);

        // Probar pulsacion del boton 0.
        buttons = 4'b0001;
        repeat (10) @(negedge clk);
        buttons = 4'b0000;

        repeat (1000) @(negedge clk);

        $display("LEDs finales: %b", leds);
        $display("Simulacion terminada");

        $finish;
    end

endmodule

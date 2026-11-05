`timescale 1ns/1ps

module game_functional_tb;

    reg clk = 0;
    reg rst_ni = 0;
    reg [3:0] buttons = 0;

    wire [3:0] leds;
    wire spi_miso;

    wire seg1_a, seg1_b, seg1_c, seg1_d;
    wire seg1_e, seg1_f, seg1_g;
    wire seg2_a, seg2_b, seg2_c, seg2_d;
    wire seg2_e, seg2_f, seg2_g;

    // Periodo de 100 ns, igual a la corrida ASIC.
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

    task wait_for_led;
        input [3:0] expected;
        input integer max_cycles;
        integer n;
        begin
            n = 0;
            while (leds !== expected && n < max_cycles) begin
                @(negedge clk);
                n = n + 1;
            end

            if (leds !== expected)
                $fatal(1, "Timeout: LED esperado %b, actual %b",
                       expected, leds);
        end
    endtask

    task wait_for_target;
        input integer max_cycles;
        integer n;
        begin
            n = 0;
            while (!(leds === 4'b0001 ||
                     leds === 4'b0010 ||
                     leds === 4'b0100 ||
                     leds === 4'b1000) &&
                   n < max_cycles) begin
                @(negedge clk);
                n = n + 1;
            end

            if (n >= max_cycles)
                $fatal(1, "No aparecio un LED objetivo");
        end
    endtask

    task wait_for_error;
        input integer max_cycles;
        integer n;
        begin
            n = 0;
            while (dut.u_soc.u_periph.digit_q !== 8'hEE &&
                   n < max_cycles) begin
                @(negedge clk);
                n = n + 1;
            end

            if (n >= max_cycles)
                $fatal(1, "No aparecio el codigo EE");
        end
    endtask

    reg [3:0] wrong_button;

    initial begin
        $dumpfile("tb/game_functional.vcd");
        $dumpvars(0, game_functional_tb);

        $display("=== PRUEBA FUNCIONAL DEL JUEGO ===");

        // Reset
        repeat (5) @(negedge clk);
        rst_ni = 1;

        repeat (100) @(negedge clk);

        // Iniciar partida
        buttons = 4'b0001;
        repeat (30) @(negedge clk);
        buttons = 0;

        // La ronda empieza con los 4 LEDs encendidos.
        wait_for_led(4'b1111, 2000);
        $display("PASS: inicio de ronda, LEDs = %b", leds);

        // Dejar que el software capture el contador inicial.
        repeat (100) @(negedge clk);

        // Adelantar el contador sin modificar el RTL.
        // 80 millones supera tanto el umbral antiguo
        // como el previsto de 75 millones de ciclos.
        dut.u_soc.u_periph.cycle_cnt_q =
            dut.u_soc.u_periph.cycle_cnt_q + 32'd80000000;

        wait_for_target(2000);
        $display("PASS: LED objetivo = %b", leds);

        // Seleccionar un boton distinto del objetivo.
        if (leds == 4'b0001)
            wrong_button = 4'b0010;
        else
            wrong_button = 4'b0001;

        buttons = wrong_button;

        wait_for_error(2000);
        $display("PASS: boton incorrecto, display = EE");

        wait_for_led(4'b0000, 2000);
        $display("PASS: LEDs apagados tras el error");

        // Liberar el boton para comenzar otra ronda.
        buttons = 0;

        wait_for_led(4'b1111, 2000);
        $display("PASS: ronda reiniciada");

        $display("=== TODAS LAS PRUEBAS PASARON ===");
        $finish;
    end

    // Watchdog de seguridad.
    initial begin
        #2000000;
        $fatal(1, "Timeout general de simulacion");
    end

endmodule

// Testbench Proyecto 4: emula a la FPGA maestra.
// Correr desde la raíz del repositorio:
//   python3 tools/pochoasm.py sw/trade.s -o sw/trade.hex
//   iverilog -g2012 -s tb_proyecto_4 -o /tmp/tb_p4 $(yosys-config --datdir)/ice40/cells_sim.v rtl/*.v rtl/espino_core/*.v tb/tb_proyecto_4.sv
//   vvp -n /tmp/tb_p4

`timescale 1ns/1ps

module tb_proyecto_4;

  // Configuración: pueden cambiar estos valores
  localparam string PROGRAMA   = "sw/trade.hex";
  localparam string SERIE      = "practica_meta.csv";
  localparam int    PERIODO_NS = 100000;   // ronda 1: 10000000, ronda 2: 1000000, ronda 3: 100000
  localparam int    NTICKS     = 20000;    // ejecuta la serie de práctica completa

  localparam int CAJA0    = 10000;
  localparam int COMISION = 5;
  localparam int SPI_NS   = 9500;          // duración de una transacción SPI

  // Pochoco SoC a 25 MHz
  logic clk = 0;
  always #20 clk = ~clk;

  logic sclk = 0, mosi = 0, cs_n = 1;
  wire  miso;

  pochoco_soc #(.MemFile(PROGRAMA)) dut (
    .i_Clk(clk), .o_LED(), .i_Switch(4'b0000),
    .o_Segment1_A(), .o_Segment1_B(), .o_Segment1_C(), .o_Segment1_D(),
    .o_Segment1_E(), .o_Segment1_F(), .o_Segment1_G(),
    .o_Segment2_A(), .o_Segment2_B(), .o_Segment2_C(), .o_Segment2_D(),
    .o_Segment2_E(), .o_Segment2_F(), .o_Segment2_G(),
    .i_SPI_SCLK(sclk), .i_SPI_MOSI(mosi), .i_SPI_CS_n(cs_n), .o_SPI_MISO(miso));

  // Lee la serie de precios (CSV "tick,price")
  int precio [20000];

  task automatic leer_serie;
    int fd, t, r;
    string encabezado;
    fd = $fopen(SERIE, "r");
    if (fd == 0) begin $display("ERROR: no se encontro %s", SERIE); $finish; end
    r = $fgets(encabezado, fd);
    for (int n = 0; n < NTICKS; n++) r = $fscanf(fd, "%d,%d\n", t, precio[n]);
    $fclose(fd);
  endtask

  // SPI modo 0: envía el precio y recibe la decisión
  int bits_x = 0;

  task automatic spi(input logic [7:0] enviar, output logic [7:0] recibido);
    cs_n = 0;
    #1000;
    for (int b = 7; b >= 0; b--) begin
      mosi = enviar[b];
      #500 sclk = 1;
      if (miso !== 1'b0 && miso !== 1'b1) bits_x++;
      recibido[b] = (miso === 1'b1);
      #500 sclk = 0;
    end
    #500 cs_n = 1;
  endtask

  // Contabilidad oficial
  int caja = CAJA0, acciones = 0, w = CAJA0, peak = CAJA0, max_dd = 0;
  int ordenes = 0;

  task automatic ejecutar(input logic [7:0] decision, input int p);
    int q = decision[5:0];
    case (decision[7:6])
      2'b01: begin                                         // comprar lo que alcance
        if (q > (caja - COMISION) / p) q = (caja - COMISION) / p;
        if (q > 0) begin caja -= q * p + COMISION; acciones += q; ordenes++; end
      end
      2'b10: begin                                         // vender lo que se tenga
        if (q > acciones) q = acciones;
        if (q > 0 && caja + q * p >= COMISION) begin caja += q * p - COMISION; acciones -= q; ordenes++; end
      end
      default: ;                                           // 00 y 11: mantener
    endcase
    w = caja + acciones * p;
    if (w > peak) peak = w;
    if (peak - w > max_dd) max_dd = peak - w;
  endtask

  // Mide trabajo de CPU desde byte_done hasta que se escribe DECISION.
  // commit cuenta instrucciones válidas que avanzan por la etapa ID.
  int ciclos = 0, instrucciones_tick = 0;
  int peor_caso = 0, peor_ic = 0, peor_cpi_milesimas = 0;
  int tick_peor_ic = 0, tick_peor_ciclos = 0, tick_peor_cpi = 0;
  int respuestas = 0, precios_perdidos = 0, tick_metrica = 0;
  int total_ciclos = 0, total_ic = 0, tiempo_tick_ns = 0;
  int peor_tiempo_ns = 0, fd_metricas;
  real cpi_tick, suma_cpi = 0.0;
  real promedio_ic, promedio_ciclos, promedio_cpi;
  bit esperando = 0;

  always @(posedge clk) begin
    if (dut.u_spi.byte_done) begin
      if (dut.u_spi.new_price_q) precios_perdidos++;      // el precio anterior no se leyó
      ciclos = 0;
      instrucciones_tick = 0;
      esperando = 1;
      tick_metrica++;
    end else if (esperando) begin
      ciclos++;
      if (dut.u_core.u_id.commit) instrucciones_tick++;

      if (dut.u_spi.wr && dut.u_spi.off == 2) begin
        respuestas++;
        tiempo_tick_ns = ciclos * 40;
        cpi_tick = instrucciones_tick == 0 ? 0.0 :
                   $itor(ciclos) / $itor(instrucciones_tick);
        total_ciclos += ciclos;
        total_ic += instrucciones_tick;
        suma_cpi = suma_cpi + cpi_tick;
        if (ciclos > peor_caso) begin
          peor_caso = ciclos;
          tick_peor_ciclos = tick_metrica - 1;
        end
        if (instrucciones_tick > peor_ic) begin
          peor_ic = instrucciones_tick;
          tick_peor_ic = tick_metrica - 1;
        end
        if (tiempo_tick_ns > peor_tiempo_ns) peor_tiempo_ns = tiempo_tick_ns;
        if (cpi_tick * 1000.0 > peor_cpi_milesimas) begin
          peor_cpi_milesimas = $rtoi(cpi_tick * 1000.0 + 0.5);
          tick_peor_cpi = tick_metrica - 1;
        end
        $fdisplay(fd_metricas, "%0d,%0d,%0d,%0.3f,%0d",
                  tick_metrica - 1, instrucciones_tick, ciclos,
                  cpi_tick, tiempo_tick_ns);
        esperando = 0;
      end
    end
  end

  // Chequeos
  int total_tests = 0, tests_aprobados = 0;

  task automatic chequear(input bit ok, input string nombre);
    total_tests++;
    if (ok) begin tests_aprobados++; $display("PASS %s", nombre); end
    else $display("FAIL %s", nombre);
  endtask

  // Simulación
  logic [7:0] decision;
  int fd, ref_q, ref_w, presupuesto;

  initial begin
    leer_serie();
    fd = $fopen("decisiones.csv", "w");
    $fdisplay(fd, "tick,precio,decision,caja,acciones,patrimonio");
    fd_metricas = $fopen("sw/resultados_reales/practica_meta_metricas_tick.csv", "w");
    $fdisplay(fd_metricas, "tick,instrucciones,ciclos,cpi,tiempo_ns");
    #4000;

    for (int n = 0; n < NTICKS; n++) begin
      spi(precio[n], decision);                            // decisión tomada con el precio anterior
      ejecutar(decision, precio[n]);                       // se ejecuta al precio actual
      $fdisplay(fd, "%0d,%0d,%02h,%0d,%0d,%0d", n, precio[n], decision, caja, acciones, w);
      #(PERIODO_NS - SPI_NS);
    end
    $fclose(fd);
    $fclose(fd_metricas);

    ref_q       = (CAJA0 - COMISION) / precio[0];
    ref_w       = CAJA0 - COMISION - ref_q * precio[0] + ref_q * precio[NTICKS - 1];
    presupuesto = (PERIODO_NS - SPI_NS) / 40;

    $display("Patrimonio final:          %0d", w);
    $display("Ordenes ejecutadas:        %0d", ordenes);
    $display("Perdida maxima:            %0d", max_dd);
    $display("No operar:                 %0d", CAJA0);
    $display("Comprar y mantener:        %0d", ref_w);
    $display("Peor caso precio->decision: %0d ciclos (disponibles: %0d)", peor_caso, presupuesto);
    promedio_ic      = $itor(total_ic) / $itor(respuestas);
    promedio_ciclos  = $itor(total_ciclos) / $itor(respuestas);
    promedio_cpi     = suma_cpi / $itor(respuestas);
    $display("Promedio por tick: IC %0.3f, ciclos %0.3f, CPI %0.4f, tiempo %0.2f ns",
             promedio_ic, promedio_ciclos, promedio_cpi, promedio_ciclos * 40.0);
    $display("Max IC: %0d en tick %0d; max ciclos/tiempo: %0d / %0d ns en tick %0d",
             peor_ic, tick_peor_ic, peor_caso, peor_tiempo_ns, tick_peor_ciclos);
    $display("Max CPI: %0.3f en tick %0d",
             peor_cpi_milesimas / 1000.0, tick_peor_cpi);
    $display("Detalle por tick en decisiones.csv");
    $display("Metricas por tick en sw/resultados_reales/practica_meta_metricas_tick.csv");

    chequear(bits_x == 0,           "MISO sin valores X");
    chequear(respuestas > 0,        "el programa escribe DECISION");
    chequear(precios_perdidos == 0, "el programa lee todos los precios");
    chequear(peor_caso < presupuesto, "la decision llega antes del siguiente tick");

    $display("Testbenchs aprobados: %0d/%0d", tests_aprobados, total_tests);
    $finish;
  end

endmodule

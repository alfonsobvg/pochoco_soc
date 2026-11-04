// Copyright 2026 Universidad de los Andes.
// Licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: SHL-0.51
//
// Course: Arquitectura de Computadores (2026)
// 
// Authors:
// - Nicolás Villegas <navillegas@miuandes.cl>


module espino_register_file (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire [3:0]  raddr_a_i,
    output wire [31:0] rdata_a_o,
    input  wire [3:0]  raddr_b_i,
    output wire [31:0] rdata_b_o,
    input  wire [3:0]  waddr_i,
    input  wire [31:0] wdata_i,
    input  wire        we_i
);

    // RV32E: 16 registros de 32 bits.
    // x0 siempre representa el valor cero.
    reg [31:0] registers [0:15];

    // Salidas registradas para conservar lectura sincrona.
    reg [31:0] rdata_a_q;
    reg [31:0] rdata_b_q;

    wire wr = we_i && (waddr_i != 4'd0);

    always @(posedge clk_i) begin

        // Puerto de lectura A
        if (raddr_a_i == 4'd0)
            rdata_a_q <= 32'b0;
        else
            rdata_a_q <= registers[raddr_a_i];

        // Puerto de lectura B
        if (raddr_b_i == 4'd0)
            rdata_b_q <= 32'b0;
        else
            rdata_b_q <= registers[raddr_b_i];

        // Escritura: x0 nunca se modifica
        if (wr)
            registers[waddr_i] <= wdata_i;

    end

    assign rdata_a_o = rdata_a_q;
    assign rdata_b_o = rdata_b_q;

    // El banco no necesita resetear sus registros.
    // rst_ni se conserva por compatibilidad.
    wire _unused = rst_ni;

endmodule

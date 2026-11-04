// Copyright 2026 Universidad de los Andes.
// Licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: SHL-0.51
//
// Course: Arquitectura de Computadores (2026)
// 
// Authors:
// - Nicolás Villegas <navillegas@miuandes.cl>


module pochoco_ram #(
    parameter NumWords = 64,
    parameter MemFile = ""
) (
    input wire clk_i,

    input wire a_req_i,
    input wire [31:0] a_addr_i,
    output reg [31:0] a_rdata_o,

    input wire b_req_i,
    input wire b_we_i,
    input wire [3:0] b_be_i,
    input wire [31:0] b_addr_i,
    input wire [31:0] b_wdata_i,
    output reg [31:0] b_rdata_o
);

    // ROM de hasta 256 instrucciones.
    wire [31:0] instruction;

    game_rom u_rom (
        .addr(a_addr_i[9:2]),
        .data(instruction)
    );

    // Conservamos la lectura sincrona original.
    always @(posedge clk_i) begin
        if (a_req_i)
            a_rdata_o <= instruction;
    end

    // RAM de datos implementada con registros.
    localparam AddrW = $clog2(NumWords);

    reg [31:0] data_mem [0:NumWords-1];
    wire [AddrW-1:0] b_word;

    assign b_word = b_addr_i[AddrW+1:2];

    always @(posedge clk_i) begin
        if (b_req_i && b_we_i) begin
            if (b_be_i[0])
                data_mem[b_word][7:0] <= b_wdata_i[7:0];

            if (b_be_i[1])
                data_mem[b_word][15:8] <= b_wdata_i[15:8];

            if (b_be_i[2])
                data_mem[b_word][23:16] <= b_wdata_i[23:16];

            if (b_be_i[3])
                data_mem[b_word][31:24] <= b_wdata_i[31:24];
        end

        // Conserva el comportamiento del puerto B original.
        b_rdata_o <= data_mem[b_word];
    end

endmodule

module asic_top (
    input  wire       clk,
    input  wire       rst_ni,
    input  wire [3:0] buttons,
    output wire [3:0] leds,

    // Display 1
    output wire seg1_a, seg1_b, seg1_c,
    output wire seg1_d, seg1_e, seg1_f, seg1_g,

    // Display 2
    output wire seg2_a, seg2_b, seg2_c,
    output wire seg2_d, seg2_e, seg2_f, seg2_g,

    // SPI
    input  wire spi_sclk,
    input  wire spi_mosi,
    input  wire spi_cs_n,
    output wire spi_miso
);

    pochoco_soc u_soc (
        .i_Clk(clk),
        .i_Rst_n(rst_ni),

        .i_Switch(buttons),
        .o_LED(leds),

        .o_Segment1_A(seg1_a),
        .o_Segment1_B(seg1_b),
        .o_Segment1_C(seg1_c),
        .o_Segment1_D(seg1_d),
        .o_Segment1_E(seg1_e),
        .o_Segment1_F(seg1_f),
        .o_Segment1_G(seg1_g),

        .o_Segment2_A(seg2_a),
        .o_Segment2_B(seg2_b),
        .o_Segment2_C(seg2_c),
        .o_Segment2_D(seg2_d),
        .o_Segment2_E(seg2_e),
        .o_Segment2_F(seg2_f),
        .o_Segment2_G(seg2_g),

        .i_SPI_SCLK(spi_sclk),
        .i_SPI_MOSI(spi_mosi),
        .i_SPI_CS_n(spi_cs_n),
        .o_SPI_MISO(spi_miso)
    );

endmodule

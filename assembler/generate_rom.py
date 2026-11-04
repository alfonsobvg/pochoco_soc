from pathlib import Path

source = Path("sw/game.hex")
destination = Path("rtl/game_rom.v")

words = [
    line.strip()
    for line in source.read_text().splitlines()
    if line.strip()
]

if len(words) > 256:
    raise ValueError("El programa supera las 256 instrucciones")

for word in words:
    if len(word) != 8:
        raise ValueError(f"Palabra inválida: {word}")
    int(word, 16)

with destination.open("w") as f:
    f.write("""
module game_rom (
    input wire [7:0] addr,
    output reg [31:0] data
);
    always @(*) begin
        case (addr)
""")

    for address, word in enumerate(words):
        f.write(
            f"            8'd{address}: data = 32'h{word};\n"
        )

    f.write("""
            default: data = 32'h00000013;
        endcase
    end
endmodule
""")

print(f"ROM generada: {len(words)} instrucciones")
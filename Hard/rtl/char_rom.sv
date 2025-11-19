module char_rom #(
    parameter logic [4:0] CHAR_HEIGHT = 16,
    parameter int NUM_OF_CHARS = 256,
    parameter int MEMORY_BYTES = $rtoi(CHAR_HEIGHT * NUM_OF_CHARS)
) (
    input  logic [11:0] char_address,
    output logic [ 7:0] data_rom
);
  // 256 characters × 16 rows = 4096 bytes
  logic [7:0] font_mem[MEMORY_BYTES];

  // Load font from hex file
  initial begin
    $readmemh("tb/char_font.hex", font_mem);
  end

  always_comb begin
    data_rom = font_mem[char_address];
  end
endmodule  //char_rom

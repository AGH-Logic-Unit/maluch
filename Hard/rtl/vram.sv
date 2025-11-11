module vram #(
    parameter int READ_ADDR_SIZE = 12,
    parameter int WRITE_ADDR_SIZE = 16,
    parameter int MEMORY_BYTES = $rtoi($pow(2, WRITE_ADDR_SIZE))
) (
    input logic rst,
    input logic clk,
    input logic [READ_ADDR_SIZE-1:0] vram_read_address,
    input logic [WRITE_ADDR_SIZE-1:0] vram_write_address,
    input logic [7:0] vram_write_data,
    output logic [7:0] vram_read_data
);
  logic nw_enable;
  assign nw_enable = vram_write_address[15];

  logic [7:0] mem[MEMORY_BYTES];

  always_ff @(negedge clk) begin : memory_read
    vram_read_data <= mem[{4'b0, vram_read_address}];
  end : memory_read

  always_ff @(posedge clk) begin : memory_write
    if (~nw_enable) mem[vram_write_address] <= vram_write_data;
  end : memory_write

endmodule  //vram

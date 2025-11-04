module vram #(
    parameter int READ_ADDR_SIZE = 12,
    parameter int WRITE_ADDR_SIZE = 16,
    parameter int MEMORY_BYTES = $rtoi($pow(2, WRITE_ADDR_SIZE))  //TODO: Properly calculate
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

  // TODO: Testbench only

  initial begin
    int data = 0;
    logic [6:0] x;
    logic [4:0] y;

    for (y = 0; y < 30; y++) begin
      for (x = 0; x < 80; x++) begin
        data++;
        mem[{4'b0, y, x}] = data[7:0];
      end
    end
  end

  logic [READ_ADDR_SIZE-1:0] rd_addr_q;
  always_ff @(negedge clk) begin : memory_read
    //rd_addr_q      <= vram_read_address;
    vram_read_data <= mem[{4'b0, vram_read_address}];  //TODO: Add some offset
  end : memory_read

  always_ff @(posedge clk) begin : memory_write
    if (~nw_enable) mem[vram_write_address] <= vram_write_data;
  end : memory_write
  /*
  always_ff @(negedge clk) begin : memory_rst
    if (rst) begin
      for (int i = 0; i < MEMORY_BYTES; i++) begin
        mem[i] = 8'b0;
      end
    end
  end : memory_rst
  */
endmodule

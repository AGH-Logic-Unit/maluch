`include "gpu_controller.sv"
`include "vga_controller.sv"
`include "vram.sv"

module graphics_card (
    input logic clk,
    input logic rst,
    input logic [15:0] io_data,
    output logic [2:0] red,
    output logic [2:0] green,
    output logic [1:0] blue,
    output logic h_sync,
    output logic v_sync,
    output logic video_enable
);
  logic [ 7:0] data_in;
  logic [19:0] address;
  logic [ 7:0] data_out;
  logic [11:0] vram_address;

  gpu_controller gpu_controller (
      .io_data(io_data),
      .v_sync(v_sync),
      .address(address),
      .vram_address(vram_address),
      .data_in(data_in),
      .data_out(data_out)
  );

  vga_controller vga_controller (
      .clk(clk),
      .rst(rst),
      .address(address),
      .v_sync(v_sync),
      .h_sync(h_sync),
      .data(data_out),
      .red(red),
      .green(green),
      .blue(blue),
      .video_enable(video_enable)
  );

  vram vram (
      .rst(rst),
      .clk(clk),
      .vram_read_address(vram_address),
      .vram_write_address(0),
      .w_data(0),
      .r_data(data_in)
  );
endmodule

`include "gpu_controller.sv"
`include "vga_controller.sv"
`include "vram.sv"

module graphics_card (
    input logic clk,
    input logic rst,
    input logic [15:0] io_data,
    input logic [15:0] cpu_write_address,
    input logic [7:0] cpu_write_data,
    output logic [2:0] red,
    output logic [2:0] green,
    output logic [1:0] blue,
    output logic h_sync,
    output logic v_sync,
    output logic video_enable
);
  logic [19:0] address;
  logic [ 7:0] data_out;
  logic [11:0] vram_read_address;
  logic [ 7:0] vram_read_data;
  logic [15:0] vram_write_address;
  logic [ 7:0] vram_write_data;

  gpu_controller gpu_controller (
      .clk(clk),
      .rst(rst),
      .io_data(io_data),
      .v_sync(v_sync),
      .address(address),
      .data_out(data_out),
      .vram_read_address(vram_read_address),
      .vram_read_data(vram_read_data),
      .vram_write_address(vram_write_address),
      .vram_write_data(vram_write_data),
      .cpu_write_address(cpu_write_address),
      .cpu_write_data(cpu_write_data)
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
      .vram_read_address(vram_read_address),
      .vram_write_address(vram_write_address),
      .vram_write_data(vram_write_data),
      .vram_read_data(vram_read_data)
  );
endmodule

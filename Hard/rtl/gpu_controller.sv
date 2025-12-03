`include "io_controller.sv"
`include "ascii_controller.sv"
`include "clear_engine.sv"

module gpu_controller (
    input  logic        clk,
    input  logic        rst,
    input  logic [ 7:0] cpu_write_data,
    input  logic [15:0] cpu_write_address,
    input  logic [19:0] address,
    input  logic [15:0] io_data,
    input  logic        v_sync,
    input  logic [ 7:0] vram_read_data,      //ascii code
    output logic [11:0] vram_read_address,
    output logic [ 7:0] vram_write_data,
    output logic [15:0] vram_write_address,
    output logic [ 7:0] data_out
);
  logic [15:0] color_data;
  logic clear_start, mode;

  io_controller io_controller (
      .clk(clk),
      .rst(rst),
      .io_data(io_data),
      .color_data(color_data),
      .clear_start(clear_start),
      .mode(mode)
  );
  logic line_mode;
  assign line_mode = mode;

  logic [4:0] curr_row;
  assign curr_row = cpu_write_address[12:8];

  logic clr_busy, clr_done;
  logic [15:0] clr_waddr;
  logic [ 7:0] clr_wdata;

  clear_engine clear_engine (
      .clk(clk),
      .rst(rst),
      .start(clear_start),
      .line_mode(line_mode),
      .line_indx(curr_row),
      .busy(clr_busy),
      .done(clr_done),
      .waddr(clr_waddr),
      .wdata(clr_wdata)
  );

  always_comb begin
    vram_write_address = clr_busy ? clr_waddr : cpu_write_address;
    vram_write_data = clr_busy ? clr_wdata : cpu_write_data;
  end

  logic [ 7:0] data_ascii;
  logic [11:0] ascii_address;

  ascii_controller ascii_controller (
      .color_data(color_data),
      .vram_read_data(vram_read_data),
      .address(address),
      .ascii_address(ascii_address),
      .data_ascii(data_ascii)
  );
  assign data_out = data_ascii;
  assign vram_read_address = ascii_address;
endmodule : gpu_controller

module gpu_controller #(
    parameter CHAR_WIDTH = 8,
    parameter CHAR_HEIGHT = 16,
    parameter BACKGROUND_COLOR = 8'h00
) (
    input  logic [19:0] address,
    input  logic [ 7:0] data_in,       //ascii code
    input  logic [15:0] io_data,
    input  logic        v_sync,
    output logic [11:0] vram_address,
    output logic [ 7:0] data_out
);
  logic [ 7:0] data_ascii;
  logic [11:0] ascii_address;
  logic [15:0] color_data;

  io_controller io_controller (
      .v_sync(v_sync),
      .io_data(io_data),
      .color_data(color_data)
  );

  ascii_controller ascii_controller (
      .color_data(color_data),
      .data_in(data_in),
      .address(address),
      .ascii_address(ascii_address),
      .data_ascii(data_ascii)
  );
  assign data_out = data_ascii;
  assign vram_address = ascii_address;
endmodule  //gpu_controller

module ascii_controller #(
    parameter CHAR_WIDTH = 8,
    parameter CHAR_HEIGHT = 16,
    parameter DISPLAY_CHAR_WIDTH = 80,
    parameter DISPLAY_CHAR_HEIGHT = 30
) (
    input  logic [15:0] color_data,
    input  logic [ 7:0] data_in,
    input  logic [19:0] address,
    output logic [11:0] ascii_address,
    output logic [ 7:0] data_ascii
);
  logic [7:0] font_color;
  logic [7:0] background_color;
  assign font_color       = color_data[15:8];  //Higher 8 bits of color_data
  assign background_color = color_data[7:0];  //Lower 8 bits of color_data

  logic [9:0] pixel_x;
  logic [9:0] pixel_y;
  assign pixel_x = address[9:0];
  assign pixel_y = address[19:10];

  logic [4:0] row;
  logic [6:0] column;
  assign row = pixel_y[8:4];
  assign column = pixel_x[9:3];

  logic [11:0] char_address;
  logic [ 7:0] data_rom;

  char_rom char_rom (
      .char_address(char_address),
      .data_rom(data_rom)
  );

  logic [2:0] index;
  always_comb begin
    index = CHAR_WIDTH - (pixel_x % CHAR_WIDTH) - 1;
    data_ascii = (data_rom[index] === 1'b1) ? font_color : background_color;
    char_address = data_in * CHAR_HEIGHT + pixel_y % CHAR_HEIGHT;
    ascii_address = {row, column};
  end
endmodule  //ascii_controller

module io_controller (
    input logic v_sync,
    input logic [15:0] io_data,
    output logic [15:0] color_data
);
  logic [7:0] color;
  logic [7:0] background_color;
  logic [7:0] font_color;
  logic [7:0] instruction;

  assign instruction = io_data[15:8];  //Higher 8 bits of instruction
  assign color       = io_data[7:0];  //Lower 8 bits of instruction

  logic color_type;  //0 - font_color | 1 - background_color
  assign color_type = instruction[1];

  always_ff @(negedge v_sync) begin : color_register  //demux
    if (color_type) font_color <= color;
    else background_color <= color;
  end : color_register

  assign color_data = {font_color, background_color};
endmodule


module char_rom (
    input  logic [11:0] char_address,
    output logic [ 7:0] data_rom
);
  // 256 characters × 16 rows = 4096 bytes
  logic [7:0] font_mem[4096];

  // Load font from hex file
  initial begin
    $readmemh("tb/char_font.hex", font_mem);
  end

  always_comb begin
    data_rom = font_mem[char_address];
  end
endmodule  //char_rom

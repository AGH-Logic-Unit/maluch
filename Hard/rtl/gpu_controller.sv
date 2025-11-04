module gpu_controller #(
    parameter CHAR_WIDTH = 8,
    parameter CHAR_HEIGHT = 16,
    parameter BACKGROUND_COLOR = 8'h00
) (
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
      .v_sync(v_sync),
      .io_data(io_data),
      .color_data(color_data),
      .clear_start(clear_start),
      .mode(mode)
  );

  //TODO: Validate if everything is ok
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
endmodule  //gpu_controller

module ascii_controller #(
    parameter CHAR_WIDTH = 8,
    parameter CHAR_HEIGHT = 16,
    parameter DISPLAY_CHAR_WIDTH = 80,
    parameter DISPLAY_CHAR_HEIGHT = 30
) (
    input  logic [15:0] color_data,
    input  logic [ 7:0] vram_read_data,
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
    char_address = vram_read_data * CHAR_HEIGHT + pixel_y % CHAR_HEIGHT;
    ascii_address = {row, column};
  end
endmodule  //ascii_controller

module io_controller (
    input logic v_sync,
    input logic [15:0] io_data,
    output logic [15:0] color_data,
    output clear_start,
    output mode  //0 - font_color | 1 - background_color
                 //0 - clear_screen | 1 - clear_line
);
  logic [7:0] color;
  logic [7:0] background_color;
  logic [7:0] font_color;
  logic [7:0] instruction;

  assign instruction = io_data[15:8];  //Higher 8 bits of instruction
  assign color       = io_data[7:0];  //Lower 8 bits of instruction

  assign mode        = instruction[0];
  assign clear_start = instruction[2];

  always_ff @(negedge v_sync) begin : color_register  //demux
    if (instruction[1]) begin
      if (~mode) font_color <= color;
      else background_color <= color;
    end
  end : color_register

  assign color_data = {font_color, background_color};
endmodule

module clear_engine #(
    parameter int COLS = 80,
    parameter int ROWS = 30,
    parameter logic [7:0] CLEAR_VALUE = 8'h20  //space
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,      // 1-cycle pulse
    input  logic        line_mode,  // 1=line, 0=full
    input  logic [ 4:0] line_indx,  // valid when line_mode=1
    output logic        busy,
    output logic        done,       // 1-cycle pulse
    output logic [15:0] waddr,      // bit15=0 => write enabled in VRAM
    output logic [ 7:0] wdata
);
  logic [6:0] x;  // 0..79
  logic [4:0] y;  // 0..29
  logic       mode_latched;
  logic [4:0] line_latched;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      busy <= 0;
      done <= 0;
      x <= '0;
      y <= '0;
      mode_latched <= 1;
      line_latched <= '0;
      waddr <= '0;
      wdata <= CLEAR_VALUE;
    end else begin
      done <= 0;
      if (!busy) begin
        // idle: keep bit15=1
        waddr <= 16'h8000;
        if (start) begin
          mode_latched <= line_mode;
          line_latched <= line_indx;
          x <= 0;
          y <= line_mode ? line_indx : 0;
          busy <= 1;
        end
      end else begin
        wdata <= CLEAR_VALUE;
        waddr <= {1'b0, 3'b000, y, x};  // bit15=0 -> write

        if (x == COLS) begin
          x <= 0;
          if (mode_latched) begin  //if line_mode
            busy <= 0;
            done <= 1;
          end else if (y == ROWS - 1) begin
            busy <= 0;
            done <= 1;
          end else begin
            y <= y + 1;
          end
        end else begin
          x <= x + 1;
        end
      end
    end
  end
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

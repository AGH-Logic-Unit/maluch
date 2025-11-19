module io_controller (
    input logic clk,
    input logic rst,
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

  always_ff @(posedge clk or posedge rst) begin : color_register  //demux
    if (rst) begin
      font_color <= 8'hFF;
      background_color <= 0;
    end else if (instruction[1]) begin
      if (~mode) font_color <= color;
      else background_color <= color;
    end
  end : color_register

  assign color_data = {font_color, background_color};
endmodule  //io_controller

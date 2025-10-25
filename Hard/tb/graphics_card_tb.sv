`timescale 1ns / 10ps
`include "graphics_card.sv"

module graphics_card_tb ();
  int fd;
  logic clk;
  logic rst;
  logic v_sync;
  logic h_sync;
  logic [15:0] io_data;
  logic [7:0] instruction;
  logic [7:0] color;
  logic [7:0] ascii_code;
  logic [2:0] red;
  logic [2:0] green;
  logic [1:0] blue;
  logic video_enable;

  assign io_data = {instruction, color};
  graphics_card graphics_card (
      .clk(clk),
      .rst(rst),
      .io_data(io_data),
      .h_sync(h_sync),
      .v_sync(v_sync),
      .red(red),
      .green(green),
      .blue(blue),
      .video_enable(video_enable)
  );

  initial begin
    fd = $fopen("build/trial", "w");
    clk = 0;
    rst = 0;
    rst = 1;
    color = 8'hFF;
    instruction = 8'h02;  //set foreground
    #1;
    #10;
    color = 8'h00;
    instruction = 8'h03;  //set background
    rst = 0;
    #20000000;
    $fclose(fd);
    $finish;
  end
  always #14 clk = ~clk;

  always_ff @(posedge clk) begin : vga_out
    if (video_enable) $fdisplay(fd, "%08b", {red, green, blue});
  end : vga_out

  initial begin
    $dumpfile("waveforms/graphics_card_tb.fst");
    $dumpvars(0, graphics_card_tb);
  end
endmodule

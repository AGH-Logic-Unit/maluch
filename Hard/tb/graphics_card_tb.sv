`timescale 1ns / 10ps
`include "graphics_card.sv"

module graphics_card_tb ();
  int fd;
  bit capturing;
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

  logic [15:0] cpu_write_address;
  logic [7:0] cpu_write_data;

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
      .video_enable(video_enable),
      .cpu_write_address(cpu_write_address),
      .cpu_write_data(cpu_write_data)
  );
  //TASKS:
  //wait N frames
  task automatic wait_frames(int n);
    repeat (n) @(negedge v_sync);
  endtask

  task automatic capture_one_frame(string path);
    fd = $fopen(path, "w");
    @(negedge v_sync);  // start of frame
    capturing = 1;
    @(negedge v_sync);  // next frame edge
    capturing = 0;
    $fclose(fd);
  endtask

  task automatic set_font_color(byte c);
    color = c;
    instruction = 8'h02;
    @(negedge v_sync);
    instruction = 8'h00;
  endtask
  task automatic set_bg_color(byte c);
    color = c;
    instruction = 8'h03;
    @(negedge v_sync);
    instruction = 8'h00;
  endtask

  //Clear_engine_tb
  task automatic start_clear(bit line_mode, int row_idx);
    // provide row for clear_engine
    cpu_write_address = 16'h8000 | (row_idx[4:0] << 8);
    // start pulse
    instruction = {5'b0, 1'b1, 1'b0, line_mode};  // 0x04 or 0x05
    @(posedge clk);
    instruction[2] = 1'b0;
  endtask

  initial begin
    // Defaults
    clk = 0;
    instruction = 8'h00;
    color = 8'h00;
    cpu_write_data = 8'h00;
    cpu_write_address = 16'h8000;
    rst = 0;

    // Holding reset for proper initialization
    rst = 1;
    repeat (4) @(posedge clk);
    rst = 0;

    @(negedge v_sync);

    set_font_color(8'hFF);  // white font
    set_bg_color(8'h00);  // black background

    wait_frames(1);
    //start_clear(0, 1);  //clear_screen
    start_clear(1, 5);  //clear_line(5)
    capture_one_frame("build/trial");

    $finish;
  end
  always #14 clk = ~clk;

  // Only one frame in png file
  always_ff @(posedge clk) begin : vga_out
    if (capturing && video_enable) $fdisplay(fd, "%08b", {red, green, blue});
  end : vga_out

  initial begin
    $dumpfile("waveforms/graphics_card_tb.fst");
    $dumpvars(0, graphics_card_tb);
  end
endmodule

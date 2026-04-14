`timescale 1ns / 10ps
`include "crc.sv"

module crc_tb();
    logic clk;
    logic _rst_pow;
    logic _rst_sw;
    logic progmem_write;

    logic _rst_cpu_out;
    logic _rst_io_out;
    logic _rst_mem_out;
    logic clk_out;

    crc crc(
        .clk(clk),
        ._rst_pow(_rst_pow),
        ._rst_sw(_rst_sw),
        .progmem_write(progmem_write),
        ._rst_cpu_out(_rst_cpu_out),
        ._rst_io_out(_rst_io_out),
        ._rst_mem_out(_rst_mem_out),
        .clk_out(clk_out)
    );

    always #1 clk = ~clk;

    task automatic check_bit(input string name, input logic got, input logic exp);
        if (got !== exp) begin
        $error("FAIL %s: got=%0b exp=%0b at t=%0t", name, got, exp, $time);
        $fatal(1);
        end
    endtask

    task automatic check_all(input logic cpu_e, input logic io_e, input logic mem_e);
        check_bit("_rst_cpu_out", _rst_cpu_out, cpu_e);
        check_bit("_rst_io_out",  _rst_io_out,  io_e);
        check_bit("_rst_mem_out", _rst_mem_out, mem_e);
    endtask

    //wait for 2-stage deassert
    task automatic wait_reset_release();
        repeat (3) @(posedge clk);
    endtask
    

    initial begin
        clk = 0;
        _rst_pow = 1'b0;      // power reset
        _rst_sw = 1'b1;
        progmem_write = 1'b0;
        
        #1;
        check_all(1'b0, 1'b0, 1'b0);

        // Release power reset
        _rst_pow = 1'b1;
        wait_reset_release();
        #1;
        check_all(1'b1, 1'b1, 1'b1);

        // Programming mode: CPU/IO in reset, MEM out of reset
        progmem_write = 1'b1;
        #1;
        check_all(1'b0, 1'b0, 1'b1);

        // Software reset during programming:
        // CPU/IO should reset, mem out of reset
        _rst_sw = 1'b0;
        #1;
        check_all(1'b0, 1'b0, 1'b1);

        // Release software reset but keep programming mode
        _rst_sw = 1'b1;
        wait_reset_release();
        #1;
        check_all(1'b0, 1'b0, 1'b1);

        // Exit programming mode: CPU/IO deassert reset
        progmem_write = 1'b0;
        #1;
        check_all(1'b1, 1'b1, 1'b1);

        // Software reset when NOT programming: all should reset
        _rst_sw = 1'b0;
        #1;
        check_all(1'b0, 1'b0, 1'b0);

        // Release software reset, wait for sync deassert
        _rst_sw = 1'b1;
        wait_reset_release();
        #1;
        check_all(1'b1, 1'b1, 1'b1);

        $display("PASS crc_tb");
        $finish;
    end
endmodule
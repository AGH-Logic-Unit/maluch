module crc(
    input  logic clk,     
    input  logic _rst_pow,   // power on reset
    input  logic _rst_sw,    // software reset
    input  logic progmem_write,

    output logic _rst_cpu_out,  
    output logic _rst_io_out,  
    output logic _rst_mem_out,  

    output logic clk_out
);

/////////////////////////////////
// CPU and IO devices reset logic
/////////////////////////////////

logic _rst_async; //for software reset and power reset
assign _rst_async = _rst_pow & _rst_sw;

// 2-staged synchronic deassertion (async assert) IO and CPU
logic _rst_s1_sync, _rst_s2_sync;

always_ff @(posedge clk or negedge _rst_async) begin : cpu_io_reset
    if(!_rst_async) begin
        _rst_s1_sync <= 1'b0;
        _rst_s2_sync <= 1'b0;
    end
    else begin
        _rst_s1_sync <= 1'b1;
        _rst_s2_sync <= _rst_s1_sync;
    end
end : cpu_io_reset

// CPU and IO devices reset when writing to memory
assign _rst_cpu_out = _rst_s2_sync & ~progmem_write;
assign _rst_io_out  = _rst_s2_sync & ~progmem_write;

/////////////////////
// Memory reset logic
/////////////////////

logic _rst_mem_req_n;
assign _rst_mem_req_n = _rst_pow & (_rst_sw | progmem_write);

// 2-staged synchronic deassertion (async assert) Memory
// Mem reset from software only if not being written to
logic _rst_mem_s1_n, _rst_mem_s2_n;

always_ff @(posedge clk or negedge _rst_mem_req_n) begin : mem_reset
    if (!_rst_mem_req_n) begin
        _rst_mem_s1_n <= 1'b0;
        _rst_mem_s2_n <= 1'b0;
    end else begin
        _rst_mem_s1_n <= 1'b1;
        _rst_mem_s2_n <= _rst_mem_s1_n;
    end
end : mem_reset

assign _rst_mem_out = _rst_mem_s2_n;

//////////////
// Clock logic
//////////////

// For now no clock division
assign clk_out = clk;
endmodule : crc
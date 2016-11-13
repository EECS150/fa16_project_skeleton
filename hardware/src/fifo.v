`include "util.vh"

module fifo #(
    parameter data_width = 8,
    parameter fifo_depth = 32,
    parameter addr_width = `log2(fifo_depth)
) (
    input clk, rst,
    
    // Write side
    input wr_en,
    input [data_width-1:0] din,
    output full,

    // Read side
    input rd_en,
    output [data_width-1:0] dout,
    output empty
);
    reg [data_width-1:0] data [fifo_depth-1:0];
    reg [addr_width-1:0] rd_ptr, wr_ptr;

    // Add your FIFO implementation here, remove lines when done
    assign full = 1'b1;
    assign empty = 1'b0;
    assign dout = 32'b0;

endmodule

//-----------------------------------------------------------------------------
//  Module: RegFile
//  Desc: An array of 32 32-bit registers
//  Input Interface:
//    clk: Clock signal
//    ra1: first read address (asynchronous)
//    ra2: second read address (asynchronous)
//    wa: write address (synchronous)
//    we: write enable (synchronous)
//    wd: data to write (synchronous)
//  Output Interface:
//    rd1: data stored at address ra1
//    rd2: data stored at address ra2
//-----------------------------------------------------------------------------
module RegFile (
    input clk,
    input [4:0] ra1,
    input [4:0] ra2,
    input [4:0] wa,
    input we,
    input [31:0] wd,
    output [31:0] rd1,
    output [31:0] rd2
);

    // Remove these lines once you have implemented your regfile
    // Hint: use a 2D reg array
    assign rd1 = 32'b0;
    assign rd2 = 32'b0;

endmodule

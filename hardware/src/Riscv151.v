/**
 * Top-level module for the RISCV processor.
 * Contains instantiations of datapath, control unit, and UART.
 */
module Riscv151 #(
    parameter CPU_CLOCK_FREQ = 50_000_000
)(
    input clk,
    input rst,
    input FPGA_SERIAL_RX,
    output FPGA_SERIAL_TX
);
   
    // Instruction memory block RAM
    imem_blk_ram inst_ram (
        .clka(clk),
        .ena(1'b1),
        .wea(4'b0),
        .addra(14'b0),
        .dina(32'b0),
        .clkb(clk),
        .addrb(14'b0),
        .doutb()
    );

    // Data memory block RAM
    dmem_blk_ram data_ram (
        .clka(clk),
        .ena(1'b1),
        .wea(4'b0),
        .addra(14'b0),
        .dina(32'b0),
        .douta()
    );

    // BIOS memory block RAM
    bios_mem bios_rom (
        .clka(clk),
        .ena(1'b1),
        .addra(12'b0),
        .douta(),
        .clkb(clk),
        .enb(1'b1),
        .addrb(12'b0),
        .doutb()
    );

    // Instantiate on-chip UART
    UART #(
        .ClockFreq(CPU_CLOCK_FREQ)
    ) uart1 (
        .Clock(clk),
        .Reset(rst),

        .DataIn(8'b0),
        .DataInValid(1'b0),
        .DataInReady(),

        .DataOut(),
        .DataOutValid(),
        .DataOutReady(1'b0),

        .SIn(FPGA_SERIAL_RX),
        .SOut(FPGA_SERIAL_TX)
    );

endmodule

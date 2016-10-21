`timescale 1ns/1ps

module EchoTestbench();
    parameter CPU_CLOCK_PERIOD = 20;
    reg Clock, Reset;
    wire FPGA_SERIAL_RX, FPGA_SERIAL_TX;

    reg   [7:0] DataIn;
    reg         DataInValid;
    wire        DataInReady;
    wire  [7:0] DataOut;
    wire        DataOutValid;
    reg         DataOutReady;

    initial Clock = 0;
    always #(CPU_CLOCK_PERIOD/2) Clock <= ~Clock;

    // Instantiate your Riscv CPU here and connect the FPGA_SERIAL_TX wires
    // to the off-chip UART we use for testing. The CPU has a UART inside it.
    Riscv151 CPU(
        .clk(Clock),
        .rst(Reset),
        .FPGA_SERIAL_RX(FPGA_SERIAL_RX),
        .FPGA_SERIAL_TX(FPGA_SERIAL_TX)
    );

    // Instantiate the off-chip UART
    UART uart(
        .Clock(Clock),
        .Reset(Reset),
        .DataIn(DataIn),
        .DataInValid(DataInValid),
        .DataInReady(DataInReady),
        .DataOut(DataOut),
        .DataOutValid(DataOutValid),
        .DataOutReady(DataOutReady),
        .SIn(FPGA_SERIAL_TX),
        .SOut(FPGA_SERIAL_RX)
    );

    initial begin
        // Reset all parts
        Reset = 0;
        DataIn = 8'h7a;
        DataInValid = 0;
        DataOutReady = 0;
        repeat (20) @(posedge Clock);

        Reset = 1;
        repeat (30) @(posedge Clock);
        Reset = 0;

        // Wait until transmit is ready
        while (!DataInReady) @(posedge Clock);

        // Send a UART packet to the CPU from the off-chip UART
        DataInValid = 1'b1;
        @(posedge Clock);
        DataInValid = 1'b0;

        // Wait for something to come back
        while (!DataOutValid) @(posedge Clock);
        $display("Got %d", DataOut);

        // Clear the off-chip UART's receiver for another UART packet
        DataOutReady = 1'b1;
        @(posedge Clock);
        DataOutReady = 1'b0;

        $finish();
    end

endmodule

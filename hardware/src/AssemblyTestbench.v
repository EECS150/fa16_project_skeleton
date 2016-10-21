`timescale 1ns/1ps

/* MODIFY THIS LINE WITH THE HIERARCHICAL PATH TO YOUR REGFILE ARRAY INDEXED WITH reg_number */
`define REGFILE_ARRAY_PATH CPU.dpath.RF.reg_file[reg_number]

module AssemblyTestbench();
    reg Clock, Reset;
    parameter CPU_CLOCK_PERIOD = 20;

    initial Clock = 0;
    always #(CPU_CLOCK_PERIOD/2) Clock <= ~Clock;

    Riscv151 CPU(
        .clk(Clock),
        .rst(Reset),
        .FPGA_SERIAL_RX(),
        .FPGA_SERIAL_TX()
    );

    // A task to check if the value contained in a register equals an expected value
    task checkReg;
        input [4:0] reg_number;
        input [31:0] expected_value;
        input [10:0] test_num;
        if (expected_value !== `REGFILE_ARRAY_PATH) begin
            $display("FAIL - test %d, got: %d, expected: %d for reg %d", test_num, `REGFILE_ARRAY_PATH, expected_value, reg_number);
            $finish();
        end
        else begin
            $display("p - test %d, got: %d for reg %d", test_num, expected_value, reg_number);
        end
    endtask

    // A task that runs the simulation until a register contains some value
    task waitForRegToEqual;
        input [4:0] reg_number;
        input [31:0] expected_value;
        while (`REGFILE_ARRAY_PATH !== expected_value) @(posedge Clock);
    endtask

    initial begin
        Reset = 0;

        // Reset the CPU
        Reset = 1;
        repeat (30) @(posedge Clock);           // Hold reset for 30 cycles
        Reset = 0;

        // Test ADD
        waitForRegToEqual(20, 32'd1);           // Run the simulation until the flag is set to 1
        checkReg(1, 32'd300, 1);                // Verify that x1 contains 300

        // Test BEQ
        waitForRegToEqual(20, 32'd2);           // Run the simulation until the flag is set to 2
        checkReg(1, 32'd500, 2);                // Verify that x1 contains 500
        checkReg(2, 32'd100, 3);                // Verify that x2 contains 100

        $display("ALL ASSEMBLY TESTS PASSED");
        $finish();
    end
endmodule

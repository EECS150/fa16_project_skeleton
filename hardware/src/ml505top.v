`define BUTTONS_DEBOUNCE_TIME 0.00076
`define BUTTONS_SATURATE_TIME 0.11364
`define ROT_EN_DEBOUNCE_TIME 0.000303
`define ROT_EN_SATURATE_TIME 0.003636

module ml505top (
    input FPGA_SERIAL_RX,       // Serial UART RX line
    output FPGA_SERIAL_TX,      // Serial UART TX line
    input USER_CLK,             // 100 Mhz clock from crystal (divided internally with PLL)

    input [7:0] GPIO_DIP,       // 8 GPIO DIP Switches
    input FPGA_ROTARY_INCA,     // Rotary Encoder Wheel A Signal
    input FPGA_ROTARY_INCB,     // Rotary Encoder Wheel B Signal
    input FPGA_ROTARY_PUSH,     // Rotary Encoder Push Button Signal (Active-high)
    input GPIO_SW_C,            // Compass Center User Pushbutton (Active-high)
    input GPIO_SW_N,            // Compass North User Pushbutton (Active-high)
    input GPIO_SW_E,            // Compass East User Pushbutton (Active-high)
    input GPIO_SW_W,            // Compass West User Pushbutton (Active-high)
    input GPIO_SW_S,            // Compass South User Pushbutton (Active-high)
    input FPGA_CPU_RESET_B,     // CPU_RESET Pushbutton (Active-LOW), signal should be interpreted as logic high when 0

    output PIEZO_SPEAKER,       // Piezo Speaker Output Line (buffered off-FPGA, drives piezo)
    output [7:0] GPIO_LED,      // 8 GPIO LEDs
    output GPIO_LED_C,          // Compass Center LED
    output GPIO_LED_N,          // Compass North LED
    output GPIO_LED_E,          // Compass East LED
    output GPIO_LED_W,          // Compass West LED
    output GPIO_LED_S,          // Compass South LED

    // AC97 Protocol Signals
    input AUDIO_BIT_CLK,
    input AUDIO_SDATA_IN,
    output AUDIO_SDATA_OUT,
    output AUDIO_SYNC,
    output FLASH_AUDIO_RESET_B
);
    // CPU clock frequency in Hz (can't be set arbitrarily)
    // Needs to be 600Mhz/x, where x is some integer, by default x = 12
    parameter CPU_CLOCK_FREQ = 50_000_000;
   localparam integer BUTTONS_DEBOUNCE_TIME = `BUTTONS_DEBOUNCE_TIME*CPU_CLOCK_FREQ;
   localparam integer BUTTONS_SATURATE_TIME = `BUTTONS_SATURATE_TIME/`BUTTONS_DEBOUNCE_TIME;
   localparam integer ROT_EN_DEBOUNCE_TIME = `ROT_EN_DEBOUNCE_TIME*CPU_CLOCK_FREQ;
   localparam integer ROT_EN_SATURATE_TIME = `ROT_EN_SATURATE_TIME/`ROT_EN_DEBOUNCE_TIME;

    // Tie the outputs low for checkpoint 1, you can use them for debugging too
    assign PIEZO_SPEAKER = 1'b0;
    assign GPIO_LED = 8'b0;
    assign GPIO_LED_C = 1'b0;
    assign GPIO_LED_N = 1'b0;
    assign GPIO_LED_E = 1'b0;
    assign GPIO_LED_W = 1'b0;
    assign GPIO_LED_S = 1'b0;
    
    wire user_clk_g, cpu_clk, cpu_clk_g, pll_lock;

    // The clocks need to be buffered before they can be used
    IBUFG user_clk_buf ( .I(USER_CLK), .O(user_clk_g) );
    BUFG  cpu_clk_buf  ( .I(cpu_clk),  .O(cpu_clk_g)  );

    /* The PLL that generates all the clocks used in this design
    * The global mult/divide ratio is set to 6. The input clk is 100MHz.
    * Therefore, freq of each output = 600MHz / CLKOUTx_DIVIDE
    */
    PLL_BASE #(
        .COMPENSATION("SYSTEM_SYNCHRONOUS"),
        .BANDWIDTH("OPTIMIZED"),
        .CLKFBOUT_MULT(6),
        .CLKFBOUT_PHASE(0.0),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER(0.100),
        .CLKIN_PERIOD(10.0),
        .CLKOUT0_DIVIDE(600_000_000 / CPU_CLOCK_FREQ),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0.0)
    ) user_clk_pll (
        .CLKFBOUT(pll_fb),
        .CLKOUT0(cpu_clk),      // This is our CPU clock (default 50 Mhz)
        .LOCKED(pll_lock),
        .CLKFBIN(pll_fb),
        .CLKIN(user_clk_g),
        .RST(1'b0)
    );

    // Synchronized versions of the input buttons and rotary encoder wheel signals
    wire rotary_inca_sync, rotary_incb_sync, rotary_push_sync,
        button_c_sync, button_n_sync, button_e_sync, button_w_sync, button_s_sync, reset_sync;

    // Debounced versions of the input buttons (already synchronized)
    wire rotary_push_deb, button_c_deb, button_n_deb, button_e_deb, button_w_deb, button_s_deb, reset_deb;

    // Debounced versions of the rotary encoder A and B signals (already synchronized)
    wire rotary_inca_deb, rotary_incb_deb;

    // Pulsed input button signals (from edge detector), you should use these in your design
    wire rotary_push, button_c, button_n, button_e, button_w, button_s, reset;

    // Signals from your rotary decoder
    wire rotary_event, rotary_left;

    // AC97 intermediary signals
    wire bit_clk;
    wire sync;
    wire sdata_out;
    wire reset_b;

    // We first pass each one of our asynchronous FPGA inputs through a 1-bit synchronizer
    synchronizer #(
        .width(9)
    ) input_synchronizer (
        .clk(cpu_clk_g),
        .async_signal({FPGA_ROTARY_INCA, FPGA_ROTARY_INCB, FPGA_ROTARY_PUSH, GPIO_SW_C, GPIO_SW_N, GPIO_SW_E, GPIO_SW_W, GPIO_SW_S, ~FPGA_CPU_RESET_B}),
        .sync_signal({rotary_inca_sync,rotary_incb_sync,rotary_push_sync,button_c_sync,button_n_sync,button_e_sync,button_w_sync,button_s_sync,reset_sync})
    );

    // Our synchronized push button inputs next pass through this multi-signal debouncer which will output a debounced version of each signal
    debouncer #(
        .width(7),
        .sampling_pulse_period(BUTTONS_DEBOUNCE_TIME),
        .saturating_counter_max(BUTTONS_SATURATE_TIME)
    ) pushbutton_debouncer (
        .clk(cpu_clk_g),
        .glitchy_signal({rotary_push_sync,button_c_sync,button_n_sync,button_e_sync,button_w_sync,button_s_sync,reset_sync}),
        .debounced_signal({rotary_push_deb,button_c_deb,button_n_deb,button_e_deb,button_w_deb,button_s_deb,reset_deb})
    );

    // The debounced push button signals pass through the edge detector so that your design can use single clock cycle wide button pulses
    edge_detector #(
        .width(7)
    ) pushbutton_edge_detector (
        .clk(cpu_clk_g),
        .signal_in({rotary_push_deb,button_c_deb,button_n_deb,button_e_deb,button_w_deb,button_s_deb,reset_deb}),
        .edge_detect_pulse({rotary_push,button_c,button_n,button_e,button_w,button_s,reset})
    );

    // Debouncer for the rotary wheel inputs
    debouncer #(
        .width(2),
        .sampling_pulse_period(ROT_EN_DEBOUNCE_TIME),
        .saturating_counter_max(ROT_EN_SATURATE_TIME)
    ) rotary_debouncer (
        .clk(cpu_clk_g),
        .glitchy_signal({rotary_inca_sync,rotary_incb_sync}),
        .debounced_signal({rotary_inca_deb,rotary_incb_deb})
    );

    // The synchronized rotary wheel A and B inputs are filtered and decoded by the rotary_decoder
    rotary_decoder wheel_decoder (
        .clk(cpu_clk_g),
        .rst(reset),
        .rotary_sync_A(rotary_inca_deb),
        .rotary_sync_B(rotary_incb_deb),
        .rotary_event(rotary_event),
        .rotary_left(rotary_left)
    );

    // Buffer the AC97 bit clock
    BUFG BitClockBuffer(.I(AUDIO_BIT_CLK), .O(bit_clk));

    // Route the sdata_out sdata_in, sync, and reset signals through IOBs (input/output blocks)
    reg sdata_out_iob, sdata_in_iob, sync_iob, reset_b_iob /* synthesis iob="true" */;
    assign AUDIO_SDATA_OUT = sdata_out_iob;
    assign AUDIO_SYNC = sync_iob;
    assign FLASH_AUDIO_RESET_B = reset_b_iob;
   
    // Drive sdata_out and sync on the rising edge of the bit_clk
    always @ (posedge bit_clk) begin
        sdata_out_iob <= sdata_out;
        sync_iob <= sync;
    end

    // Sample sdata_in on the falling edge of the bit_clk
    always @ (negedge bit_clk) begin
        sdata_in_iob <= AUDIO_SDATA_IN;
    end

    // Drive the reset signal through an IOB clocked with the system clock
    always @ (posedge cpu_clk_g) begin
      reset_b_iob <= reset_b;
    end

    ac97_controller #(
        .SYS_CLK_FREQ(CPU_CLOCK_FREQ)
    ) audio_controller (
        .sdata_in(sdata_in_iob),
        .sdata_out(sdata_out),
        .bit_clk(bit_clk),
        .sample_fifo_dout(),
        .sample_fifo_empty(),
        .sample_fifo_rd_en(),
        .sync(sync),
        .reset_b(reset_b),
        .volume_control(4'b0),
        .system_clock(cpu_clk_g),
        .system_reset(reset)
    );
   
    // RISC-V 151 CPU
    Riscv151 #(
        .CPU_CLOCK_FREQ(CPU_CLOCK_FREQ)
    ) CPU(
        .clk(cpu_clk_g),
        .rst(reset),
        .FPGA_SERIAL_RX(FPGA_SERIAL_RX),
        .FPGA_SERIAL_TX(FPGA_SERIAL_TX)
    );

endmodule

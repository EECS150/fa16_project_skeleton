`timescale 1ns/100ps

`define SECOND 1000000000
`define MS 1000000
`define SYSTEM_CLK_PERIOD 20
`define SYSTEM_CLK_FREQ 50000000

`define master_volume_reg codec.ControlRegs[2]
`define headph_volume_reg codec.ControlRegs[4]
`define pcmout_volume_reg codec.ControlRegs[24]
`define ac97_pcm_L codec.Slot3
`define ac97_pcm_R codec.Slot4

module ac97testbench();
   reg sys_clk = 0;
   reg rst = 0;
   reg [19:0] din [15:0]; // tone data we are sending to codec
   reg [19:0] check_values_L[15:0];
   reg [19:0] check_values_R[15:0];
   reg [7:0]  din_index;
   reg [7:0]  store_index;
   reg [10:0] store_counter;
   reg        empty = 0;
   reg        last_empty = 0;             

   wire       bit_clk;
   wire       sync, rst_b, rd_en;
   wire       dout;

   integer    i;

   parameter volume = 4'b1111;
   parameter head = 16'b11111_00000000000;
   parameter master_addr = {1'b0, 7'h2, 12'd0};
   parameter headph_addr = {1'b0, 7'h4, 12'd0};
   parameter pcmout_addr = {1'b0, 7'h18, 12'd0};
   parameter master_data = {3'b0, 1'b1, volume, 3'b0, 1'b1, volume, 4'd0};
   parameter headph_data = {3'b0, 1'b1, volume, 3'b0, 1'b1, volume, 4'd0};
   parameter pcmout_data = {3'b0, 5'b01000, 3'b0, 5'b01000, 4'd0};

   task set_up_data;
      begin
         din[0] = 19'd0000;
         din[1] = 19'd1500;
         din[2] = 19'd2500;
         din[3] = 19'd3500;
         din[4] = 19'd4500;
         din[5] = 19'd5500;
         din[6] = 19'd6500;
         din[7] = 19'd7500;
         din[8] = 19'd8500;
         din[9] = 19'd9500;
         din[10] = 19'd10500;
         din[11] = 19'd11500;
         din[12] = 19'd12500;
         din[13] = 19'd13500;
         din[14] = 19'd14500;
         din[15] = 19'd15500;
      end
   endtask

   // Left here as a debugging tool
   task check_pcm_data;
      input [19:0] expected_value;
      begin
         if (expected_value !== `ac97_pcm_L) $display("FAIL: expected PCM data to be %h, got: %h", expected_value, `ac97_pcm_L);
         else $display("PASS: expected PCM data to be %h, got: %h", expected_value, `ac97_pcm_L);
         if (`ac97_pcm_L !== `ac97_pcm_R) $display("FAIL: Left and right PCM data not equal");
      end
   endtask // check_pcm_data

   task compare_pcm_values;
      begin
         for(i = 0; i < 16; i = i + 1) begin
            if (din[i] !== check_values_L[i]) $display("FAIL: expected PCM data to be %d, got: %d", din[i], check_values_L[i]);
            else $display("PASS: expected PCM data to be %d, got: %d", din[i], check_values_L[i]);
            if (check_values_L[i] !== check_values_R[i]) $display("FAIL: Left and right PCM data not equal");
         end
      end
   endtask
   
   task check_master_volume;
      input [15:0] expected_value;
      if (expected_value !== `master_volume_reg) begin
         $display("FAIL: expected master volume to be %h, got: %h", expected_value, `master_volume_reg);
      end else begin
         $display("Got expected master volume");
      end
   endtask

   task check_headph_volume;
      input [15:0] expected_value;
      if (expected_value !== `headph_volume_reg) begin
         $display("FAIL: expected master volume to be %h, got: %h", expected_value, `headph_volume_reg);
      end else begin
         $display("Got expected headphone volume");
      end
   endtask

   task check_pcmout_volume;
      input [15:0] expected_value;
      if (expected_value !== `pcmout_volume_reg) begin
         $display("FAIL: expected master volume to be %h, got: %h", expected_value, `pcmout_volume_reg);
      end else begin
         $display("Got expected PCM volume");
      end
   endtask   
   
   always #(`SYSTEM_CLK_PERIOD/2) sys_clk <= ~sys_clk;
     
   always @(posedge bit_clk) begin

      empty <= $random();
      store_counter <= store_counter + 1;

      if (store_counter == 255 && ~last_empty) begin
         check_values_L[store_index] <= `ac97_pcm_L;
         check_values_R[store_index] <= `ac97_pcm_R;
         store_index <= store_index+1;
      end
   
      if (rd_en) begin
         last_empty <= empty;
         din_index <= din_index+1;
         store_counter <= 0;
      end
         
      if(din_index == 17) begin
         check_master_volume(master_data[19:4]);
         check_headph_volume(headph_data[19:4]);
         check_pcmout_volume(pcmout_data[19:4]);
         compare_pcm_values();
         $finish();
      end  
   end
   
   ac97_CodecModel codec(
                   .SDATA_OUT(dout),
                   .BIT_CLOCK(bit_clk),
                   .SDATA_IN(),
                   .SYNC(sync),
                   .RST(rst_b)
                   );
   
   ac97_controller #(
                     .SYS_CLK_FREQ(`SYSTEM_CLK_FREQ))
   AC97(
        .bit_clk(bit_clk),
        .tone_data(din[din_index]),
        .fifo_empty(empty),
        .fifo_rd_en(rd_en),
        .sdata_out(dout),
        .sync(sync),
        .reset_b(rst_b),
        .volume_control(volume),
        .system_clock(sys_clk),
        .system_reset(rst)
        );
 
   initial begin
      // Pulse the system reset to the ac97 controller
      din_index <= 0;
      store_index <= 0;
      store_counter <= 0;
      @(posedge sys_clk);
      rst <= 1'b1;
      @(posedge sys_clk);
      rst <= 1'b0;
      set_up_data();
   end

endmodule

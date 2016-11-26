module ac97_CodecModel(
                      input SDATA_OUT,
                      output BIT_CLOCK,
                      output SDATA_IN,
                      input SYNC,
                      input RST);

   localparam RST2CLK_del = 200;
   localparam ReadyDelay = 10000;
   localparam bit_half_cycle = 40.7;

   reg                      RawBitClock, BitClockEnable, CodecReady;
   reg                      Last_SYNC;
   reg [15:0]               Slot0;
   reg [19:0]               Slot1, Slot2, Slot3, Slot4;
   reg [19:0]               OutShift;
   reg [9:0]                BitCount;
   reg [15:0]               ControlRegs[0:127];

   wire                     StartFrame;

   initial begin
	  RawBitClock =			1'b0;
	  BitClockEnable =		RST;

	  // Initial/Default Control Register Values
      // not all are used for the purposes of project
	  ControlRegs[0] =		16'h0D40;	// Reset
	  ControlRegs[2] =		16'h8000;	// Master Volume
	  ControlRegs[4] =		16'h8000;	// Line Level Volume
	  ControlRegs[6] =		16'h8000;	// Mono Volume
	  ControlRegs[10] =		16'h0000;	// PC_Beep Volume
	  ControlRegs[12] =		16'h8008;	// Phone Volume
	  ControlRegs[14] =		16'h8008;	// Mic Volume
	  ControlRegs[16] =		16'h8808;	// Line In Volume
	  ControlRegs[18] =		16'h8808;	// CD Volume
	  ControlRegs[20] =		16'h8808;	// Video Volume
	  ControlRegs[22] =		16'h8808;	// Aux Volume
	  ControlRegs[24] =		16'h8808;	// PCM Out Volume
	  ControlRegs[26] =		16'h0000;	// Record Select
	  ControlRegs[28] =		16'h8000;	// Record Gain
	  ControlRegs[32] =		16'h0000;	// General Purpose
	  ControlRegs[34] =		16'h0101;	// 3D Control (Read Only)
	  ControlRegs[36] =		16'h0000;	// Reserved
	  ControlRegs[38] =		16'h000X;	// Powerdown Control/Status
	  ControlRegs[40] =		16'hX001;	// Extended Audio ID
	  ControlRegs[42] =		16'h0000;	// Extended Audio Control/Status
	  ControlRegs[44] =		16'hBB80;	// PCM DAC Rate
	  ControlRegs[50] =		16'hBB80;	// PCM ADC Rate
	  ControlRegs[90] =		16'h0000;	// Reserved
	  ControlRegs[116] =		16'h0000;	// Reserved
	  ControlRegs[122] =		16'h0000;	// Reserved
	  ControlRegs[124] =		16'h4E53;	// Vendor ID1
	  ControlRegs[126] =		16'h4349;	// Vendor ID2

	  Slot0 =				20'h00000;
	  Slot1 =				20'h00000;
	  Slot2 =				20'h00000;
	  Slot3 =				20'h00000;
	  Slot4 =				20'h00000;
   end
   
   assign BIT_CLOCK = RawBitClock & BitClockEnable;
   assign StartFrame = SYNC & ~Last_SYNC;
   
   always begin
      @(negedge RST) begin
         BitClockEnable <= 1'b0;
      end
      @(posedge RST) begin #(RST2CLK_del)
         BitClockEnable <= @(posedge RawBitClock) 1'b1;
      end
   end

    always begin
      @(negedge RST) begin
         CodecReady <= 1'b0;
      end
      @(posedge RST) begin #(ReadyDelay)
         CodecReady <= @(posedge RawBitClock) 1'b1;
      end
   end
   
   always #(bit_half_cycle) RawBitClock <= ~RawBitClock;

   always @(posedge BIT_CLOCK) begin
      if (StartFrame) BitCount <= 9'h0; 
      else BitCount <= BitCount + 1;
   end
   
   always @(posedge BIT_CLOCK) begin
      if (~RST) Last_SYNC <= 1'b0;
      else Last_SYNC <= SYNC;
   end     

   always @(negedge BIT_CLOCK) begin
      if (~RST) OutShift = 20'h00000;
      else OutShift = {OutShift[18:0], SDATA_OUT};
   end

   always @(negedge BIT_CLOCK) begin
      if (CodecReady & (BitCount == 15)) begin
         Slot0 = OutShift[15:0];
      end
      if (CodecReady & (BitCount == 35)) begin
         Slot1 = OutShift[19:0];
      end
      if (CodecReady & (BitCount == 55)) begin
         Slot2 = OutShift[19:0];
         if (Slot0[13] & ~Slot1[19]) begin
            if ((Slot1[18:12] != 7'h22) & (Slot1[18:12] != 7'h7C) & (Slot1[18:12] != 7'h7E)) ControlRegs[Slot1[18:12]] = Slot2[19:4];
         end
      end
      if (CodecReady & (BitCount == 75)) begin
         Slot3 = OutShift[19:0];
      end
      if (CodecReady & (BitCount == 95)) begin
         Slot4 = OutShift[19:0];
      end
   end

   specify
		specparam
			tBC =		81.4,
			tBCH =		32.6,
			tBCL =		32.6,
			tSYNC =		20833.3,
			tSYNCH =	1302.4,
			tSYNCL =	19454.6,
			tDSETUP =	15,
			tDHOLD =	5,
			tRST_LOW =	1000;
		$width		(posedge BIT_CLOCK,			tBCH);
		$width		(negedge BIT_CLOCK,			tBCL);
		$width		(posedge SYNC,			tSYNCH);
		$width		(negedge SYNC,			tSYNCL);
		$width		(negedge RST,			tRST_LOW);
		$period		(posedge BIT_CLOCK,			tBC);
		$period		(negedge BIT_CLOCK,			tBC);
		$period		(posedge SYNC,			tSYNC);
		$period		(negedge SYNC,			tSYNC);
		$setuphold	(negedge BIT_CLOCK,	SDATA_IN,	tDSETUP, tDHOLD);
	endspecify
   
endmodule
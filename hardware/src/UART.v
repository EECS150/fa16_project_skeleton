module UART #(
    parameter ClockFreq = 50_000_000,
    parameter BaudRate = 115_200
)(
    input   Clock,
    input   Reset,

    input   [7:0] DataIn,
    input         DataInValid,
    output        DataInReady,

    output  [7:0] DataOut,
    output        DataOutValid,
    input         DataOutReady,

    input         SIn,
    output        SOut
);

    wire SOutInt, SInInt;

    // Route the SOut and SIn signals through IOBs (input/output blocks) 
    // for minimal off-chip skew and high drive strength
    reg SInTemp, SOutTemp /* synthesis iob="true" */;

    always @ (posedge Clock) begin
        SOutTemp <= Reset ? 1'b1 : SOutInt;
        SInTemp <= Reset ? 1'b1 : SIn;
    end
    assign SOut = SOutTemp;
    assign SInInt = SInTemp;

    UATransmit #(
        .ClockFreq(ClockFreq),
        .BaudRate(BaudRate)
    ) uatransmit (
        .Clock(Clock),
        .Reset(Reset),
        .DataIn(DataIn),
        .DataInValid(DataInValid),
        .DataInReady(DataInReady),
        .SOut(SOutInt)
    );

    UAReceive #(
        .ClockFreq(ClockFreq),
        .BaudRate(BaudRate)
    ) uareceive (
        .Clock(Clock),
        .Reset(Reset),
        .DataOut(DataOut),
        .DataOutValid(DataOutValid),
        .DataOutReady(DataOutReady),
        .SIn(SInInt)
    );

endmodule

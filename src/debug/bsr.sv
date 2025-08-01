module bsr #(parameter WIDTH=8) (
    // Primary Inputs
    input logic [WIDTH-1:0]  DataIn,
    input logic              ScanIn,
    // Control Signals
    input logic              ShiftDR, ClockDR, UpdateDR, Mode,
    // Outputs
    output logic [WIDTH-1:0] Qout,
    output logic             ScanOut,
);
    logic [WIDTH-1:0] shiftreg;
    logic [WIDTH-1:0] y;
    
    always @(posedge ClockDR)
      shiftreg <= ShiftDR ? {ScanIn, shiftreg[WIDTH-1:1]} : DataIn;

    always @(posedge UpdateDR)
      y <= shiftreg;
    
    assign Qout = Mode ? y : DataIn;
    assign ScanOut = shiftreg[0];
endmodule // bsr


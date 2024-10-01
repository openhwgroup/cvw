module fetchbuffer
  import cvw::*;
#(
    parameter cvw_t P
) (
    input  logic        clk, reset,
    input  logic        StallD, flush,
    input  logic [31:0] writeData,
    output logic [31:0] readData,
    output logic        StallF
);
  localparam [31:0] nop = 32'h00000013;
  logic      [31:0] readf0, readf1, readf2, readMuxed;
  logic      [2:0]  readPtr, writePtr;
  logic             empty, full;

  assign empty  = |(readPtr & writePtr); // Bitwise and the read&write ptr, and or the bits of the result together
  assign full   = |({writePtr[1:0], writePtr[2]} & readPtr); // Same as above but left rotate writePtr to "add 1"
  assign StallF = full;

  // will go in a generate block once this is parameterized
  flopenr f0 (.clk, .reset(reset | flush), .en(writePtr[0]), .d(writeData), .q(readf0)); 
  flopenr f1 (.clk, .reset(reset | flush), .en(writePtr[1]), .d(writeData), .q(readf1));
  flopenr f2 (.clk, .reset(reset | flush), .en(writePtr[2]), .d(writeData), .q(readf2));

  always_comb begin : readMuxes
    // Mux read data from the three registers
    case (readPtr)
      3'b001:  readMuxed = readf0;
      3'b010:  readMuxed = readf1;
      3'b001:  readMuxed = readf2;
      default: readMuxed = nop; // just in case?
    endcase
    // issue nop when appropriate
    readData = empty ? nop : readMuxed;
  end

  always_ff @(posedge clk) begin : shiftRegister
    if (reset) begin
      writePtr <= 3'b001;
      readPtr  <= 3'b001;
    end else begin
      writePtr <= ~full ? {writePtr[1:0], writePtr[2]} : writePtr;
      readPtr <= ~(StallD | empty) ? {readPtr[1:0], readPtr[2]} : readPtr;
    end
  end
endmodule

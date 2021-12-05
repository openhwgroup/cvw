module BUFGCE_DIV #(parameter string DivideAmt = "1")
  (input logic I, input logic CLR, input logic CE, output logic O);

  integer PulseCount = 0;
  logic   Q;
  
  always_ff @(posedge I, posedge CLR) begin
    if(CLR) PulseCount <= 0;
    else begin
      if(PulseCount < (DivideAmt.atoi()/2 - 1))
	PulseCount <= PulseCount + 1;
      else
	PulseCount <= 0;
    end
  end

  assign zero = PulseCount == 0;
  

  flopenr #(1) ToggleFlipFLop
    (.d(~Q),
     .q(Q),
     .clk(I),
     .reset(CLR),                     // reset when told by outside
     .en(zero));        // only update when counter overflows

  if (DivideAmt != "1")
    assign O = Q;
  else
    assign O = I;

endmodule

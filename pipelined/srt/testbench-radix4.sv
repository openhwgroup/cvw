
`include "wally-config.vh"
`define DIVLEN ((`NF<`XLEN) ? `XLEN : `NF)

///////////
// clock //
///////////
module clock(clk);
  output clk;
 
  // Internal clk signal
  logic clk;
 
endmodule

//////////
// testbench //
//////////
module testbenchradix4;
  logic              clk;
  logic              req;
  logic              DivDone;
  logic [63:0]       a, b;
  logic [51:0]       afrac, bfrac;
  logic [10:0]       aExp, bExp;
  logic              asign, bsign;
  logic [51:0]       r, rOTFC;
  logic [`DIVLEN-1:0]  Quot, QuotOTFC;
  logic [54:0]       rp, rm;   // positive quotient digits
 
  // Test parameters
  parameter MEM_SIZE = 40000;
  parameter MEM_WIDTH = 64+64+64;
 
  `define memr  63:0
  `define memb  127:64
  `define mema  191:128

  // Test logicisters
  logic [MEM_WIDTH-1:0] Tests [0:MEM_SIZE];  // Space for input file
  logic [MEM_WIDTH-1:0] Vec;  // Verilog doesn't allow direct access to a
                            // bit field of an array 
  logic [63:0] correctr, nextr, diffn, diffp;
  logic [10:0] DivExp;
  logic        DivSgn;
  integer testnum, errors;

  // Divider
  srtradix4 srtradix4(.clk, .DivStart(req), 
                .XExpE(aExp), .YExpE(bExp), .DivExp,
                .XSgnE(asign), .YSgnE(bsign), .DivSgn,
                .XFrac(afrac), .YFrac(bfrac), 
                .SrcA('0), .SrcB('0),
                .W64(1'b0), .Signed(1'b0), .Int(1'b0), .Sqrt(1'b0), .DivDone,
                .Quot, .Rem());

  // Counter


    initial
    forever
      begin
        clk = 1; #17;
        clk = 0; #17;
      end


  // Read test vectors from disk
  initial
    begin
      testnum = 0; 
      errors = 0;
      $readmemh ("testvectors", Tests);
      Vec = Tests[testnum];
      a = Vec[`mema];
      {asign, aExp, afrac} = a;
      b = Vec[`memb];
      {bsign, bExp, bfrac} = b;
      nextr = Vec[`memr];
      r = Quot[`DIVLEN-1:`DIVLEN - 52];
      req <= 1;
    end
  
  // Apply directed test vectors read from file.

  always @(posedge clk)
    begin
      r = Quot[`DIVLEN-1:`DIVLEN - 52];
      if (DivDone) begin
        req <= 1;
        diffp = correctr[51:0] - r;
        diffn = r - correctr[51:0];
        if ((DivSgn !== correctr[63]) | (DivExp !== correctr[62:52]) | ($signed(diffn) > 1) | ($signed(diffp) > 1) | (diffn === 64'bx) | (diffp === 64'bx)) // check if accurate to 1 ulp
          begin
            errors = errors+1;
            $display("result was %h_%h, should be %h %h %h\n", DivExp, r, correctr, diffn, diffp);
            $display("failed\n");
            $stop;
          end
        if (afrac === 52'hxxxxxxxxxxxxx)
          begin
            $display("%d Tests completed successfully", testnum);
            $stop;
          end
	end
      if (req) 
	begin
	  req <= 0;
	  correctr = nextr;
	  testnum = testnum+1;
	  Vec = Tests[testnum];
	  $display("a = %h  b = %h",a,b);
    a = Vec[`mema];
    {asign, aExp, afrac} = a;
    b = Vec[`memb];
    {bsign, bExp, bfrac} = b;
    nextr = Vec[`memr];
	end
    end
 
endmodule
 

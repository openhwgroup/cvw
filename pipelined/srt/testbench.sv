/////////////
// counter //
/////////////
module counter(input  logic clk, 
               input  logic req, 
               output logic done);
 
   logic    [5:0]  count;

  // This block of control logic sequences the divider
  // through its iterations.  You may modify it if you
  // build a divider which completes in fewer iterations.
  // You are not responsible for the (trivial) circuit
  // design of the block.

  always @(posedge clk)
    begin
      if      (count == 54) done <= #1 1;
      else if (done | req) done <= #1 0;	
      if (req) count <= #1 0;
      else     count <= #1 count+1;
    end
endmodule

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
module testbench;
  logic         clk;
  logic        req;
  logic         done;
  logic [63:0] a;
  logic [63:0] b;
  logic [63:0] result;
  logic [51:0] r;
  logic [54:0] rp, rm;   // positive quotient digits
  logic [10:0] e; // output exponent
 
  // input logic for Unpacker
  // input logic  [63:0] X, Y, Z,  - numbers
  // input logic         FmtE,  ---- format, 1 is for double precision, 0 is single
  // input logic  [2:0]  FOpCtrlE, ---- controling operations for FPU, 1 is sqrt, 0 is divide
  // all variables are commented in fpu.sv

  // output logic from Unpacker
  logic        XSgnE, YSgnE, ZSgnE;
  logic [10:0] XExpE, YExpE, ZExpE; // exponent
  logic [52:0] XManE, YManE, ZManE;
  logic XNormE;
  logic XNaNE, YNaNE, ZNaNE;
  logic XSNaNE, YSNaNE, ZSNaNE;
  logic XDenormE, YDenormE, ZDenormE; // denormals
  logic XZeroE, YZeroE, ZZeroE;
  logic [10:0] BiasE; // currrently hardcoded, will probs be removed
  logic XInfE, YInfE, ZInfE;
  logic XExpMaxE; // says exponent is all ones, can ignore

  // Test parameters
  parameter MEM_SIZE = 60000;
  parameter MEM_WIDTH = 64+64+64;
 
  `define memr  63:0
  `define memb  127:64
  `define mema  191:128

  // Test logicisters
  logic [MEM_WIDTH-1:0] Tests [0:MEM_SIZE];  // Space for input file
  logic [MEM_WIDTH-1:0] Vec;  // Verilog doesn't allow direct access to a
                            // bit field of an array 
  logic    [63:0] correctr, nextr, diffn, diffp;
  integer testnum, errors;

  // Unpacker
  // Note: BiasE will probably get taken out eventually
  unpack unpack(.X({1'b1,a[62:0]}), .Y({1'b1,b[62:0]}), .Z(64'b0), .FmtE(1'b1), .FOpCtrlE(3'b0),
                  .XSgnE(XSgnE), .YSgnE(YSgnE), .ZSgnE(ZSgnE), .XExpE(XExpE), .YExpE(YExpE), .ZExpE(ZExpE),
                  .XManE(XManE), .YManE(YManE), .ZManE(ZManE), .XNormE(XNormE), .XNaNE(XNaNE), .YNaNE(YNaNE), .ZNaNE(ZNaNE),
                  .XSNaNE(XSNaNE), .YSNaNE(YSNaNE), .ZSNaNE(ZSNaNE), .XDenormE(XDenormE), .YDenormE(YDenormE), .ZDenormE(ZDenormE),
                  .XZeroE(XZeroE), .YZeroE(YZeroE), .ZZeroE(ZZeroE), .BiasE(BiasE),
                  .XInfE(XInfE), .YInfE(YInfE), .ZInfE(ZInfE), .XExpMaxE(XExpMaxE));

  // Divider
  srt  #(52) srt(.clk, .Start(req), 
                .Stall(1'b0), .Flush(1'b0), 
                .SrcXExpE(XExpE), .SrcYExpE(YExpE),
                .SrcXFrac(XManE[51:0]), .SrcYFrac(YManE[51:0]), 
                .SrcA('0), .SrcB('0), .Fmt(2'b00), 
                .W64(1'b0), .Signed(1'b0), .Int(1'b0), .Sqrt(1'b0), 
                .Quot(r), .Rem(), .Exp(e), .Flags());

  assign result = {1'b0, e, r};

  // Counter
  counter counter(clk, req, done);


    initial
    forever
      begin
        clk = 1; #17;
        clk = 0; #16;
      end


  // Read test vectors from disk
  initial
    begin
      testnum = 0; 
      errors = 0;
      $readmemh ("testvectors", Tests);
      Vec = Tests[testnum];
      a = Vec[`mema];
      b = Vec[`memb];
      nextr = Vec[`memr];
      req <= #5 1;
    end
  
  // Apply directed test vectors read from file.

  always @(posedge clk)
    begin
      if (done) 
	begin
	  req <= #5 1;
    diffp = correctr - result;
    diffn = result - correctr;
	  if (($signed(diffn) > 1) | ($signed(diffp) > 1)) // check if accurate to 1 ulp
	    begin
	      errors = errors+1;
        $display("a = %h  b = %h result = %h",a,b,correctr);
	      $display("result was %h, should be %h %h %h\n", result, correctr, diffn, diffp);
        $display("at fail");
	      $display("failed\n");
	      $stop;
	    end
	  if (a === 64'hxxxxxxxxxxxxxxxx)
	    begin
 	      $display("%d Tests completed successfully", testnum);
	      $stop;
	    end
	end
      if (req) 
	begin
	  req <= #5 0;
	  correctr = nextr;
    $display("pre increment");
	  testnum = testnum+1;
    a = Vec[`mema];
	  b = Vec[`memb];
	  Vec = Tests[testnum];
	  $display("a = %h  b = %h result = %h",a,b,nextr);
	  nextr = Vec[`memr];
    $display("after increment");
	end
    end
 
endmodule
 

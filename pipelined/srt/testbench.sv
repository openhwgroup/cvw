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
  logic [51:0] a;
  logic [51:0] b;
  logic  [51:0] r;
  logic [54:0] rp, rm;   // positive quotient digits
 
  // Test parameters
  parameter MEM_SIZE = 40000;
  parameter MEM_WIDTH = 52+52+52;
 
  `define memr  51:0
  `define memb  103:52
  `define mema  155:104

  // Test logicisters
  logic [MEM_WIDTH-1:0] Tests [0:MEM_SIZE];  // Space for input file
  logic [MEM_WIDTH-1:0] Vec;  // Verilog doesn't allow direct access to a
                            // bit field of an array 
  logic    [51:0] correctr, nextr, diffn, diffp;
  integer testnum, errors;

  // Divider
  srt  #(52) srt(.clk, .Start(req), 
                .Stall(1'b0), .Flush(1'b0), 
                .SrcXFrac(a), .SrcYFrac(b), 
                .SrcA('0), .SrcB('0), .Fmt(2'b00), 
                .W64(1'b0), .Signed(1'b0), .Int(1'b0), .Sqrt(1'b0), 
                .Quot(r), .Rem(), .Flags());

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
    diffp = correctr - r;
    diffn = r - correctr;
	  if (($signed(diffn) > 1) | ($signed(diffp) > 1)) // check if accurate to 1 ulp
	    begin
	      errors = errors+1;
	      $display("result was %h, should be %h %h %h\n", r, correctr, diffn, diffp);
	      $display("failed\n");
	      $stop;
	    end
	  if (a === 52'hxxxxxxxxxxxxx)
	    begin
 	      $display("%d Tests completed successfully", testnum);
	      $stop;
	    end
	end
      if (req) 
	begin
	  req <= #5 0;
	  correctr = nextr;
	  testnum = testnum+1;
	  Vec = Tests[testnum];
	  $display("a = %h  b = %h",a,b);
	  a = Vec[`mema];
	  b = Vec[`memb];
	  nextr = Vec[`memr];
	end
    end
 
endmodule
 

`define DIVLEN 64

/////////////
// counter //
/////////////
// module counter(input  logic clk, 
//                input  logic req, 
//                output logic done);
 
//    logic    [7:0]  count;

//   // This block of control logic sequences the divider
//   // through its iterations.  You may modify it if you
//   // build a divider which completes in fewer iterations.
//   // You are not responsible for the (trivial) circuit
//   // design of the block.

//   always @(posedge clk)
//     begin
//       if      (count == `DIVLEN + 2) done <= #1 1;
//       else if (done | req) done <= #1 0;	
//       if (req) count <= #1 0;
//       else     count <= #1 count+1;
//     end
// endmodule

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
  logic              clk;
  logic              req;
  logic              done;
  logic              Int;
  logic [63:0]       a, b;
  logic [51:0]       afrac, bfrac;
  logic [10:0]       aExp, bExp;
  logic              asign, bsign;
  logic [51:0]       r;
  logic [63:0]       rInt;
  logic [`DIVLEN-1:0]  Quot;
 
  // Test parameters
  parameter MEM_SIZE = 40000;
  parameter MEM_WIDTH = 64+64+64+64;
 
  // INT TEST SIZES
  // `define memrem  63:0 
  // `define memr  127:64
  // `define memb  191:128
  // `define mema  255:192

  // FLOAT TEST SIZES
  `define memr  63:0 
  `define memb  127:64
  `define mema  191:128

  // Test logicisters
  logic [MEM_WIDTH-1:0] Tests [0:MEM_SIZE];  // Space for input file
  logic [MEM_WIDTH-1:0] Vec;  // Verilog doesn't allow direct access to a
                            // bit field of an array 
  logic [63:0] correctr, nextr, diffn, diffp;
  logic [10:0] rExp;
  logic        rsign;
  integer testnum, errors;

  assign Int = 1'b0;

  // Divider
  srt srt(.clk, .Start(req), 
                .Stall(1'b0), .Flush(1'b0), 
                .XExp(aExp), .YExp(bExp), .rExp,
                .XSign(asign), .YSign(bsign), .rsign,
                .SrcXFrac(afrac), .SrcYFrac(bfrac), 
                .SrcA(a), .SrcB(b), .Fmt(2'b00), 
                .W64(1'b1), .Signed(1'b0), .Int, .Sqrt(1'b0), 
                .Quot, .Rem(), .Flags(), .done);

  // Counter
  // counter counter(clk, req, done);


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
      {asign, aExp, afrac} = a;
      b = Vec[`memb];
      {bsign, bExp, bfrac} = b;
      nextr = Vec[`memr];
      r = Quot[(`DIVLEN - 1):(`DIVLEN - 52)];
      rInt = Quot;
      req <= #5 1;
    end
  
  // Apply directed test vectors read from file.

  always @(posedge clk)
    begin
      r = Quot[(`DIVLEN - 1):(`DIVLEN - 52)];
      rInt = Quot;
      if (done) begin
        if (~Int) begin
        req <= #5 1;
        diffp = correctr[51:0] - r;
        diffn = r - correctr[51:0];
        if ((rsign !== correctr[63]) | (rExp !== correctr[62:52]) | ($signed(diffn) > 1) | ($signed(diffp) > 1) | (diffn === 64'bx) | (diffp === 64'bx)) // check if accurate to 1 ulp
          begin
            errors = errors+1;
            $display("result was %h_%h, should be %h %h %h\n", rExp, r, correctr, diffn, diffp);
            $display("failed\n");
            $stop;
          end
        if (afrac === 52'hxxxxxxxxxxxxx)
          begin
            $display("%d Tests completed successfully", testnum);
            $stop;
          end
        end else begin
          req <= #5 1;
          diffp = correctr[63:0] - rInt;
          diffn = rInt - correctr[63:0];
          if (($signed(diffn) > 1) | ($signed(diffp) > 1) | (diffn === 64'bx) | (diffp === 64'bx)) // check if accurate to 1 ulp
            begin
              errors = errors+1;
              $display("result was %h, should be %h %h %h\n", rInt, correctr, diffn, diffp);
              $display("failed\n");
              $stop;
            end
        if (afrac === 52'hxxxxxxxxxxxxx)
          begin
            $display("%d Tests completed successfully", testnum);
            $stop;
          end
	      end
      end
    if (req) begin
      req <= #5 0;
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
 

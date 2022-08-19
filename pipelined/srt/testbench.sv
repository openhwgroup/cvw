`include "wally-config.vh"

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
  logic               clk;
  logic               req;
  logic               done;
  logic               Int, Sqrt, Mod;
  logic [`XLEN-1:0]   a, b;
  logic [`NF-1:0]     afrac, bfrac;
  logic [`NE-1:0]     aExp, bExp;
  logic               asign, bsign;
  logic [`NF-1:0]     r;
  logic [`XLEN-1:0]   rInt;
  logic [`DIVLEN-1:0] Quot;
 
  // Test parameters
  parameter MEM_SIZE = 40000;
  parameter MEM_WIDTH = 64+64+64;
 
  // Test sizes
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

  // Equip Int, Sqrt, or IntMod test
  assign Int =  1'b0;
  assign Mod =  1'b0;
  assign Sqrt = 1'b1;

  // Divider
  srt srt(.clk, .Start(req), 
                .Stall(1'b0), .Flush(1'b0), 
                .XExp(aExp), .YExp(bExp), .rExp,
                .XSign(asign), .YSign(bsign), .rsign,
                .SrcXFrac(afrac), .SrcYFrac(bfrac), 
                .SrcA(a), .SrcB(b), .Fmt(2'b00), 
                .W64(1'b1), .Signed(1'b0), .Int, .Mod, .Sqrt, 
                .Result(Quot), .Flags(), .done);

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
      $readmemh ("sqrttestvectors", Tests);
      Vec = Tests[testnum];
      a = Vec[`mema];
      {asign, aExp, afrac} = a;
      b = Vec[`memb];
      {bsign, bExp, bfrac} = b;
      nextr = Vec[`memr];
      r = Quot[(`DIVLEN - 2):(`DIVLEN - `NF - 1)];
      rInt = Quot;
      req <= #5 1;
    end
  
  // Apply directed test vectors read from file.

  always @(posedge clk) begin
    r = Quot[(`DIVLEN - 2):(`DIVLEN - `NF - 1)];
    rInt = Quot;
    if (done) begin
      if (~Int & ~Sqrt) begin // This test case checks floating point division
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
      end else if (~Sqrt) begin // This test case works for both integer divide and integer modulo
        req <= #5 1;
        diffp = correctr[63:0] - rInt;
        if (($signed(diffp) != 0) | (diffp === 64'bx)) // check if accurate to 1 ulp
          begin
            errors = errors+1;
            $display("result was %h, should be %h %h\n", rInt, correctr, diffp);
            $display("failed\n");
          end
        if (afrac === 52'hxxxxxxxxxxxxx)
        begin
          $display("%d Tests completed successfully", testnum - errors);
          $stop;
        end
      end else begin // This test case verifies square root
        req <= #5 1;
        diffp = correctr[51:0] - r;
        diffn = r - correctr[51:0];
        if ((rExp !== correctr[62:52]) | ($signed(diffn) > 1) | ($signed(diffp) > 1) | (diffn === 64'bx) | (diffp === 64'bx)) // check if accurate to 1 ulp
          begin
            errors = errors + 1;
            $display("result was %h, should be %h %h %h\n", r, correctr, diffn, diffp);
            $display("failed\n");
          end
        if (afrac === 52'hxxxxxxxxxxxxx) begin 
          $display("%d Tests completed successfully", testnum-errors);
          $stop; end 
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
 

module testbench();
  logic        clk, reset;
  logic        a, b, c, s, cout, sexpected, coutexpected;
  logic [31:0] vectornum, errors;
  logic [4:0]  testvectors[10000:0];
  integer cycle;

  // instantiate device under test
  fulladder dut(a, b, c, s, cout);

  // generate clock
  always 
    begin
      clk = 1; #5; clk = 0; #5;
      cycle = cycle + 1;
      $display("cycle: %x vectornum %x testvectors[vectornum]: %b", cycle, vectornum, testvectors[vectornum]);
    end

  // at start of test, load vectors and pulse reset
  initial
    begin
      $dumpfile("fulladder.vcd");
      $dumpvars;
      $readmemb("fulladder.tv", testvectors);
      cycle = 0;
      vectornum = 0; errors = 0;
      reset = 1; #22; reset = 0;
    end

  // apply test vectors on rising edge of clk
  always @(posedge clk)
    begin
      #1; {a, b, c, coutexpected, sexpected} = testvectors[vectornum];
    end

  // check results on falling edge of clk
  always @(negedge clk)
    if (~reset) begin // skip during reset
      if (s !== sexpected | cout !== coutexpected) begin  // check result
        $display("Error: inputs = %b", {a, b, c});
        $display("  outputs cout s = %b%b (%b%b expected)",cout, s, coutexpected, sexpected);
        errors = errors + 1;
      end
      vectornum = vectornum + 1;
      //if (testvectors[vectornum] === 5'bx) begin 
      if (vectornum === 10) begin 
        $display("%d tests completed with %d errors", 
	           vectornum, errors);
        $finish;
      end
    end

endmodule

module fulladder(input  logic a, b, c,
                 output logic s, cout);

  assign s = a ^ b ^ c;
  assign cout = (a & b) | (a & c) | (b & c); 
endmodule

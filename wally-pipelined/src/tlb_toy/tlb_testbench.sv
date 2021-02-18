module testbench();
  logic clk, reset;

  // DUT inputs
  logic [31:0] PCF;
  logic [31:0] PageTableEntryF;
  logic ITLBWriteF, ITLBFlushF;

  // DUT outputs
  logic [31:0] PCPF;
  logic ITLBMissF, ITLBHitF;

  // Testbench signals
  logic [33:0] expected;
  logic [31:0] vectornum, errors;
  logic [99:0] testvectors[10000:0];

  // instantiate device under test
  tlb_toy dut(.*);

  // generate clock
  always begin
    clk=1; #5; clk=0; #5;
  end

  // at start of test, load vectors and pulse reset
  initial begin
    $readmemb("tlb_toy.tv", testvectors);
    vectornum = 0; errors = 0; reset = 1; #22; reset = 0;
  end

  // apply test vectors on rising edge of clk
  always @(posedge clk) begin
    #1; {PCF, PageTableEntryF, ITLBWriteF, ITLBFlushF, expected} = testvectors[vectornum];
  end

  // check results on falling edge of clk
  always @(negedge clk)
    if (~reset) begin // skip during reset
      if ({PCPF, ITLBMissF, ITLBHitF} !== expected) begin // check result
      $display("Error: PCF = %b, write = %b, data = %b, flush = %b", PCF,
        ITLBWriteF, PageTableEntryF, ITLBFlushF);
      $display(" outputs = %b %b %b (%b expected)",
        PCPF, ITLBMissF, ITLBHitF, expected);
      errors = errors + 1;
    end
    vectornum = vectornum + 1;
    if (testvectors[vectornum] === 100'bx) begin
      $display("%d tests completed with %d errors", vectornum, errors);
      $stop;
    end
  end
endmodule 

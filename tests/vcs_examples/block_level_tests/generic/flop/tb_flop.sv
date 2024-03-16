module tb_flop;

  logic clk, reset, clear, en, load, set;
  logic [7:0] d, val;
  logic d_sync;
  logic [7:0] q_flop, q_flopenl, q_flopenrc, q_flopenr, q_flopens, q_flopen, q_flopr;
  logic q_sync;

  // Instantiate the top module
  top_flop dut(
    .clk(clk), .reset(reset), .clear(clear), .en(en), .load(load), .set(set),
    .d(d), .val(val),
    .q_flop(q_flop), .q_flopenl(q_flopenl), .q_flopenrc(q_flopenrc), .q_flopenr(q_flopenr), .q_flopens(q_flopens), .q_flopen(q_flopen), .q_flopr(q_flopr),
    .d_sync(d_sync), .q_sync(q_sync)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // Generate a clock with 100MHz frequency
  end

  // Apply random inputs and dump VCD
  initial begin
    $dumpfile("tb_flop.vcd");
    $dumpvars(0, tb_flop);

    reset = 1; clear = 0; en = 0; load = 0; set = 0; d = 0; val = 0; d_sync = 0;
    #10 reset = 0; // Release reset after 10ns

    repeat (100) begin
      #10; // Every 10ns, apply new random inputs
      reset = $random; clear = $random; en = $random; load = $random; set = $random;
      d = $urandom%256; val = $urandom%256; d_sync = $urandom%2;
    end

    $finish;
  end
endmodule


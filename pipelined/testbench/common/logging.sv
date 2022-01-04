module logging(
  input logic clk, reset,
  input logic [31:0] HADDR,
  input logic [1:0]  HTRANS);

  always @(posedge clk)
    if (HTRANS != 2'b00 & HADDR == 0)
      $display("%t Warning: access to memory address 0\n", $realtime);
endmodule


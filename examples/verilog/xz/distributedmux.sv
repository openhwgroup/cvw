// xz.sv
// David_Harris@hmc.edu 30 January 2022
// Demonstrate impact of x and z.

// load with vsim xz.sv

module testbench();
  logic [3:0] d0, d1, d2;
  logic       s0, s1, s2;
  tri   [3:0] y;

  distributedmux dut(.d0, .d1, .d2, .s0, .s1, .s2, .y);

  initial begin
      d0 = 4'b0000; d1 = 4'b0101; // d2 unknown (xxxx)
      s0 = 0; s1 = 0; s2 = 0; 
      #10;  // y should be floating
      s0 = 1;
      #10; //y should be driven to 0000
      s0 = 0; s1 = 1; 
      #10; // y should be driven to 0101
      s0 = 1;
      #10; // y should be driven to 0x0x because of contention on bits 0 and 2
      s0 = 0; s1 = 0; s2 = 1;
      #10; // y should be driven to unknown because d2 is unknown
  end
endmodule

module tristate #(parameter WIDTH=32) (
  input  logic [WIDTH-1:0] a,
  input  logic             en, 
  output logic [WIDTH-1:0] y); 

  assign y = en ? a : 'z;
endmodule 

module distributedmux(
  input  logic [3:0] d0, d1, d2,
  input  logic       s0, s1, s2,
  output tri   [3:0] y); 

  tristate #(4) t0(d0, s0, y);
  tristate #(4) t1(d1, s1, y);
  tristate #(4) t2(d2, s2, y);
endmodule

module gpio #(parameter WIDTH=16) (
  input  logic [WIDTH-1:0] GPIOOutVal, GPIOEn,
  output logic [WIDTH-1:0] GPIOInVal,
  inout  tri   [WIDTH-1:0] GPIOPin); 

  assign GPIOInVal = GPIOPin;
  tristate #(1) ts[WIDTH-1:0](GPIOOutVal, GPIOEn, GPIOPin);
endmodule

module silly(output logic [128:0] y);
  assign y = 'bz;
endmodule
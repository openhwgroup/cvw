module TSDN28HPCPA128X64M4FW( 
  input  logic          CLKA, 
  input  logic          CLKB, 
  input  logic          CEBA, 
  input  logic          CEBB, 
  input  logic          WEBA,
  input  logic          WEBB,
  input  logic [6:0]    AA, 
  input  logic [6:0]    AB, 
  input  logic [63:0]   DA,
  input  logic [63:0]   DB,
  input  logic [63:0]   BWEBA, 
  input  logic [63:0]   BWEBB, 
  output logic [63:0]   QA,
  output logic [63:0]   QB
);
endmodule

module TSDN28HPCPA2048X64MMFW( 
  input  logic          CLKA, 
  input  logic          CLKB, 
  input  logic          CEBA, 
  input  logic          CEBB, 
  input  logic          WEBA,
  input  logic          WEBB,
  input  logic [8:0]    AA, 
  input  logic [8:0]    AB, 
  input  logic [63:0]   DA,
  input  logic [63:0]   DB,
  input  logic [63:0]   BWEBA, 
  input  logic [63:0]   BWEBB, 
  output logic [63:0]   QA,
  output logic [63:0]   QB
);
endmodule


module generic64x128ROM( 
  input  logic          CLK, 
  input  logic           CEB, 
  input  logic [6:0]    A, 
  output logic [31:0]   Q
);
endmodule

module ts3n28hpcpa128x64m8m( 
  input  logic        CLK, 
  input  logic        CEB, 
  input  logic [6:0]  A, 
  output logic [63:0] Q
);
endmodule

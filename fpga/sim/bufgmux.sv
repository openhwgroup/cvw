module BUFGMUX(input logic I1, input logic I0, input logic S, output logic O);

  assign O = S ? I1 : I0;
endmodule

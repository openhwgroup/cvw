module divremsqrtearlyterm import cvw::*;  #(parameter cvw_t P) (
  input  logic [P.DIVb+3:0]    WS, WC,            // Q4.DIVb
  input  logic [P.DIVb+3:0]    D,                 // Q4.DIVb
  input  logic [P.DIVb:0]      FirstUM,   // U1.DIVb
  input  logic [P.DIVb+1:0]    FirstC,            // Q2.DIVb
  input  logic                 Firstun, SqrtE,
  output logic                 WZeroE
);
    aplusbeq0 #(P.DIVb+4) wspluswceq0(WS, WC, weq0E);

  if (P.RADIX == 2) begin: R2EarlyTerm
    logic [P.DIVb+3:0] FZeroE, FZeroSqrtE, FZeroDivE;
    logic [P.DIVb+2:0] FirstK;
    logic wfeq0E;
    logic [P.DIVb+3:0] WCF, WSF;

    assign FirstK = ({1'b1, FirstC} & ~({1'b1, FirstC} << 1));
    assign FZeroSqrtE = {FirstUM[P.DIVb], FirstUM, 2'b0} | {FirstK,1'b0};    // F for square root
    assign FZeroDivE =  D << 1;                                    // F for divide
    mux2 #(P.DIVb+4) fzeromux(FZeroDivE, FZeroSqrtE, SqrtE, FZeroE);
    csa #(P.DIVb+4) fadd(WS, WC, FZeroE, 1'b0, WSF, WCF); // compute {WCF, WSF} = {WS + WC + FZero};
    aplusbeq0 #(P.DIVb+4) wcfpluswsfeq0(WCF, WSF, wfeq0E);
    assign WZeroE = weq0E|(wfeq0E & Firstun);
  end else begin
    assign WZeroE = weq0E;
  end 
endmodule

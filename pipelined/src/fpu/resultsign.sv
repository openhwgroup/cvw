`include "wally-config.vh"

module resultsign(
    input logic [2:0]   FrmM,
    input logic         PSgnM, ZSgnEffM,
    input logic         ZInfM,
    input logic         InfIn,
    input logic         FmaOp,
    input logic [`NE+1:0] SumExp,
    input logic         SumZero,
    input logic         Mult,
    input logic         Round,
    input logic         Sticky,
    input logic         RoundSgn,
    output logic        ResSgn
);

    logic ZeroSgn;
    logic InfSgn;
    logic Underflow;
    // logic ResultSgnTmp;

    // Determine the sign if the sum is zero
    //      if cancelation then 0 unless round to -infinity
    //      if multiply then Psgn
    //      otherwise psign
    assign Underflow = SumExp[`NE+1] | ((SumExp == 0) & (Round|Sticky));
    assign ZeroSgn = (PSgnM^ZSgnEffM)&~Underflow&~Mult ? FrmM[1:0] == 2'b10 : PSgnM;


    // is the result negitive
    //  if p - z is the Sum negitive
    //  if -p + z is the Sum positive
    //  if -p - z then the Sum is negitive
    assign InfSgn = ZInfM ? ZSgnEffM : PSgnM;
    assign ResSgn = InfIn&FmaOp ? InfSgn : SumZero&FmaOp ? ZeroSgn : RoundSgn;

endmodule
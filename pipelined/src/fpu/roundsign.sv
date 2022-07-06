`include "wally-config.vh"

module roundsign(
    input logic         PSgnM, ZSgnEffM,
    input logic         InvZM,
    input logic         XSgnM,
    input logic         YSgnM,
    input logic         NegSumM,
    input logic         FmaOp,
    input logic         DivOp,
    input logic         CvtOp,
    input logic         CvtResSgnM,
    output logic        RoundSgn
);

    logic FmaResSgnTmp;
    logic DivSgn;

    // is the result negitive
    //  if p - z is the Sum negitive
    //  if -p + z is the Sum positive
    //  if -p - z then the Sum is negitive
    assign FmaResSgnTmp = NegSumM^PSgnM; //*** move to execute stage

    // assign FmaResSgnTmp = InvZM&(ZSgnEffM)&NegSumM | InvZM&PSgnM&~NegSumM | (ZSgnEffM&PSgnM);

    assign DivSgn = XSgnM^YSgnM;

    // Sign for rounding calulation
    assign RoundSgn = (FmaResSgnTmp&FmaOp) | (CvtResSgnM&CvtOp) | (DivSgn&DivOp);

endmodule
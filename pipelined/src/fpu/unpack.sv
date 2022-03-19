`include "wally-config.vh"

module unpack ( 
    input logic  [`FLEN-1:0] X, Y, Z,
    input logic  [`FPSIZES/3:0]       FmtE,
    input logic  [2:0]  FOpCtrlE,
    output logic        XSgnE, YSgnE, ZSgnE,
    output logic [`NE-1:0] XExpE, YExpE, ZExpE,
    output logic [`NF:0] XManE, YManE, ZManE,
    output logic XNormE,
    output logic XNaNE, YNaNE, ZNaNE,
    output logic XSNaNE, YSNaNE, ZSNaNE,
    output logic XDenormE, YDenormE, ZDenormE,
    output logic XZeroE, YZeroE, ZZeroE,
    output logic XInfE, YInfE, ZInfE,
    output logic XExpMaxE
);
 
    logic [`NF-1:0] XFracE, YFracE, ZFracE;
    logic           XExpNonzero, YExpNonzero, ZExpNonzero;
    logic           XFracZero, YFracZero, ZFracZero; // input fraction zero
    logic           XExpZero, YExpZero, ZExpZero; // input exponent zero
    logic           YExpMaxE, ZExpMaxE;  // input exponent all 1s
    
    if (`FPSIZES == 1) begin
        assign XSgnE = X[`FLEN-1];
        assign YSgnE = Y[`FLEN-1];
        assign ZSgnE = Z[`FLEN-1];

        assign XExpE = X[`FLEN-2:`NF]; 
        assign YExpE = Y[`FLEN-2:`NF]; 
        assign ZExpE = Z[`FLEN-2:`NF]; 

        assign XFracE = X[`NF-1:0];
        assign YFracE = Y[`NF-1:0];
        assign ZFracE = Z[`NF-1:0];

        assign XExpNonzero = |XExpE; 
        assign YExpNonzero = |YExpE;
        assign ZExpNonzero = |ZExpE;

        assign XExpMaxE = &XExpE;
        assign YExpMaxE = &YExpE;
        assign ZExpMaxE = &ZExpE;
    

    end else if (`FPSIZES == 2) begin

        logic  [`LEN1-1:0]   XLen1, YLen1, ZLen1; // Bottom half or NaN, if not properly NaN boxed

        // Check NaN boxing, If the value is not properly NaN boxed, set the value to a quiet NaN
        assign XLen1 = &X[`FLEN-1:`LEN1] ? X[`LEN1-1:0] : {1'b0, {`NE1+1{1'b1}}, (`NF1-1)'(0)};
        assign YLen1 = &Y[`FLEN-1:`LEN1] ? Y[`LEN1-1:0] : {1'b0, {`NE1+1{1'b1}}, (`NF1-1)'(0)};
        assign ZLen1 = &Z[`FLEN-1:`LEN1] ? Z[`LEN1-1:0] : {1'b0, {`NE1+1{1'b1}}, (`NF1-1)'(0)};  

        assign XSgnE = FmtE ? X[`FLEN-1] : XLen1[`LEN1-1];
        assign YSgnE = FmtE ? Y[`FLEN-1] : YLen1[`LEN1-1];
        assign ZSgnE = FmtE ? Z[`FLEN-1] : ZLen1[`LEN1-1];

        // example double to single conversion:
        // 1023 = 0011 1111 1111
        // 127  = 0000 0111 1111 (subtract this)
        // 896  = 0011 1000 0000
        // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
        // dexp = 0bdd dbbb bbbb 
        // also need to take into account possible zero/denorm/inf/NaN values
        assign XExpE = FmtE ? X[`FLEN-2:`NF] : {XLen1[`LEN1-2], {`NE-`NE1{~XLen1[`LEN1-2]&~XExpZero|XExpMaxE}}, XLen1[`LEN1-3:`NF1]}; 
        assign YExpE = FmtE ? Y[`FLEN-2:`NF] : {YLen1[`LEN1-2], {`NE-`NE1{~YLen1[`LEN1-2]&~YExpZero|YExpMaxE}}, YLen1[`LEN1-3:`NF1]}; 
        assign ZExpE = FmtE ? Z[`FLEN-2:`NF] : {ZLen1[`LEN1-2], {`NE-`NE1{~ZLen1[`LEN1-2]&~ZExpZero|ZExpMaxE}}, ZLen1[`LEN1-3:`NF1]}; 

        assign XFracE = FmtE ? X[`NF-1:0] : {XLen1[`NF1-1:0], (`NF-`NF1)'(0)};
        assign YFracE = FmtE ? Y[`NF-1:0] : {YLen1[`NF1-1:0], (`NF-`NF1)'(0)};
        assign ZFracE = FmtE ? Z[`NF-1:0] : {ZLen1[`NF1-1:0], (`NF-`NF1)'(0)};

        assign XExpNonzero = FmtE ? |X[`FLEN-2:`NF] : |XLen1[`LEN1-2:`NF1]; 
        assign YExpNonzero = FmtE ? |Y[`FLEN-2:`NF] : |YLen1[`LEN1-2:`NF1];
        assign ZExpNonzero = FmtE ? |Z[`FLEN-2:`NF] : |ZLen1[`LEN1-2:`NF1];

        assign XExpMaxE = FmtE ? &X[`FLEN-2:`NF] : &XLen1[`LEN1-2:`NF1];
        assign YExpMaxE = FmtE ? &Y[`FLEN-2:`NF] : &YLen1[`LEN1-2:`NF1];
        assign ZExpMaxE = FmtE ? &Z[`FLEN-2:`NF] : &ZLen1[`LEN1-2:`NF1];
    

    end else if (`FPSIZES == 3) begin
        logic  [`LEN1-1:0]   XLen1, YLen1, ZLen1; // Bottom half or NaN, if not properly NaN boxed
        logic  [`LEN2-1:0]   XLen2, YLen2, ZLen2; // Bottom half or NaN, if not properly NaN boxed
        
        // Check NaN boxing, If the value is not properly NaN boxed, set the value to a quiet NaN
        assign XLen1 = &X[`FLEN-1:`LEN1] ? X[`LEN1-1:0] : {1'b0, {`NE1+1{1'b1}}, (`NF1-1)'(0)};
        assign YLen1 = &Y[`FLEN-1:`LEN1] ? Y[`LEN1-1:0] : {1'b0, {`NE1+1{1'b1}}, (`NF1-1)'(0)};
        assign ZLen1 = &Z[`FLEN-1:`LEN1] ? Z[`LEN1-1:0] : {1'b0, {`NE1+1{1'b1}}, (`NF1-1)'(0)}; 

        assign XLen2 = &X[`FLEN-1:`LEN2] ? X[`LEN2-1:0] : {1'b0, {`NE2+1{1'b1}}, (`NF2-1)'(0)};
        assign YLen2 = &Y[`FLEN-1:`LEN2] ? Y[`LEN2-1:0] : {1'b0, {`NE2+1{1'b1}}, (`NF2-1)'(0)};
        assign ZLen2 = &Z[`FLEN-1:`LEN2] ? Z[`LEN2-1:0] : {1'b0, {`NE2+1{1'b1}}, (`NF2-1)'(0)}; 

        always_comb begin
            case (FmtE)
                `FMT: begin
                    assign XSgnE = X[`FLEN-1];
                    assign YSgnE = Y[`FLEN-1];
                    assign ZSgnE = Z[`FLEN-1];

                    assign XExpE = X[`FLEN-2:`NF]; 
                    assign YExpE = Y[`FLEN-2:`NF]; 
                    assign ZExpE = Z[`FLEN-2:`NF]; 

                    assign XFracE = X[`NF-1:0];
                    assign YFracE = Y[`NF-1:0];
                    assign ZFracE = Z[`NF-1:0];

                    assign XExpNonzero = |X[`FLEN-2:`NF]; 
                    assign YExpNonzero = |Y[`FLEN-2:`NF];
                    assign ZExpNonzero = |Z[`FLEN-2:`NF];

                    assign XExpMaxE = &X[`FLEN-2:`NF];
                    assign YExpMaxE = &Y[`FLEN-2:`NF];
                    assign ZExpMaxE = &Z[`FLEN-2:`NF];
                end
                `FMT1: begin
                    assign XSgnE = XLen1[`LEN1-1];
                    assign YSgnE = YLen1[`LEN1-1];
                    assign ZSgnE = ZLen1[`LEN1-1];

                    // example double to single conversion:
                    // 1023 = 0011 1111 1111
                    // 127  = 0000 0111 1111 (subtract this)
                    // 896  = 0011 1000 0000
                    // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
                    // dexp = 0bdd dbbb bbbb 
                    // also need to take into account possible zero/denorm/inf/NaN values
                    assign XExpE = {XLen1[`LEN1-2], {`NE-`NE1{~XLen1[`LEN1-2]&~XExpZero|XExpMaxE}}, XLen1[`LEN1-3:`NF1]}; 
                    assign YExpE = {YLen1[`LEN1-2], {`NE-`NE1{~YLen1[`LEN1-2]&~YExpZero|YExpMaxE}}, YLen1[`LEN1-3:`NF1]}; 
                    assign ZExpE = {ZLen1[`LEN1-2], {`NE-`NE1{~ZLen1[`LEN1-2]&~ZExpZero|ZExpMaxE}}, ZLen1[`LEN1-3:`NF1]}; 

                    assign XFracE = {XLen1[`NF1-1:0], (`NF-`NF1)'(0)};
                    assign YFracE = {YLen1[`NF1-1:0], (`NF-`NF1)'(0)};
                    assign ZFracE = {ZLen1[`NF1-1:0], (`NF-`NF1)'(0)};

                    assign XExpNonzero = |XLen1[`LEN1-2:`NF1]; 
                    assign YExpNonzero = |YLen1[`LEN1-2:`NF1];
                    assign ZExpNonzero = |ZLen1[`LEN1-2:`NF1];

                    assign XExpMaxE = &XLen1[`LEN1-2:`NF1];
                    assign YExpMaxE = &YLen1[`LEN1-2:`NF1];
                    assign ZExpMaxE = &ZLen1[`LEN1-2:`NF1];
                end
                `FMT2: begin
                    assign XSgnE = XLen2[`LEN2-1];
                    assign YSgnE = YLen2[`LEN2-1];
                    assign ZSgnE = ZLen2[`LEN2-1];

                    // example double to single conversion:
                    // 1023 = 0011 1111 1111
                    // 127  = 0000 0111 1111 (subtract this)
                    // 896  = 0011 1000 0000
                    // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
                    // dexp = 0bdd dbbb bbbb 
                    // also need to take into account possible zero/denorm/inf/NaN values
                    assign XExpE = {XLen2[`LEN2-2], {`NE-`NE2{~XLen2[`LEN2-2]&~XExpZero|XExpMaxE}}, XLen2[`LEN2-3:`NF2]}; 
                    assign YExpE = {YLen2[`LEN2-2], {`NE-`NE2{~YLen2[`LEN2-2]&~YExpZero|YExpMaxE}}, YLen2[`LEN2-3:`NF2]}; 
                    assign ZExpE = {ZLen2[`LEN2-2], {`NE-`NE2{~ZLen2[`LEN2-2]&~ZExpZero|ZExpMaxE}}, ZLen2[`LEN2-3:`NF2]}; 

                    assign XFracE = {XLen2[`NF2-1:0], (`NF-`NF2)'(0)};
                    assign YFracE = {YLen2[`NF2-1:0], (`NF-`NF2)'(0)};
                    assign ZFracE = {ZLen2[`NF2-1:0], (`NF-`NF2)'(0)};

                    assign XExpNonzero = |XLen2[`LEN2-2:`NF2]; 
                    assign YExpNonzero = |YLen2[`LEN2-2:`NF2];
                    assign ZExpNonzero = |ZLen2[`LEN2-2:`NF2];

                    assign XExpMaxE = &XLen2[`LEN2-2:`NF2];
                    assign YExpMaxE = &YLen2[`LEN2-2:`NF2];
                    assign ZExpMaxE = &ZLen2[`LEN2-2:`NF2];
                end
                default: begin
                    assign XSgnE = 0;
                    assign YSgnE = 0;
                    assign ZSgnE = 0;
                    assign XExpE = 0; 
                    assign YExpE = 0;
                    assign ZExpE = 0; 
                    assign XFracE = 0;
                    assign YFracE = 0;
                    assign ZFracE = 0;
                    assign XExpNonzero = 0; 
                    assign YExpNonzero = 0;
                    assign ZExpNonzero = 0;
                    assign XExpMaxE = 0;
                    assign YExpMaxE = 0;
                    assign ZExpMaxE = 0;
                end
            endcase
        end

    end else begin
        logic  [`LEN1-1:0]   XLen1, YLen1, ZLen1; // Bottom half or NaN, if not properly NaN boxed
        logic  [`LEN2-1:0]   XLen2, YLen2, ZLen2; // Bottom half or NaN, if not properly NaN boxed
        logic  [`LEN2-1:0]   XLen3, YLen3, ZLen3; // Bottom half or NaN, if not properly NaN boxed
        
        // Check NaN boxing, If the value is not properly NaN boxed, set the value to a quiet NaN
        assign XLen1 = &X[`FLEN-1:`D_LEN] ? X[`D_LEN-1:0] : {1'b0, {`D_NE+1{1'b1}}, (`D_NF-1)'(0)};
        assign YLen1 = &Y[`FLEN-1:`D_LEN] ? Y[`D_LEN-1:0] : {1'b0, {`D_NE+1{1'b1}}, (`D_NF-1)'(0)};
        assign ZLen1 = &Z[`FLEN-1:`D_LEN] ? Z[`D_LEN-1:0] : {1'b0, {`D_NE+1{1'b1}}, (`D_NF-1)'(0)}; 

        assign XLen2 = &X[`FLEN-1:`S_LEN] ? X[`S_LEN-1:0] : {1'b0, {`S_NE+1{1'b1}}, (`S_NF-1)'(0)};
        assign YLen2 = &Y[`FLEN-1:`S_LEN] ? Y[`S_LEN-1:0] : {1'b0, {`S_NE+1{1'b1}}, (`S_NF-1)'(0)};
        assign ZLen2 = &Z[`FLEN-1:`S_LEN] ? Z[`S_LEN-1:0] : {1'b0, {`S_NE+1{1'b1}}, (`S_NF-1)'(0)}; 

        assign XLen3 = &X[`FLEN-1:`H_LEN] ? X[`H_LEN-1:0] : {1'b0, {`H_NE+1{1'b1}}, (`H_NF-1)'(0)};
        assign YLen3 = &Y[`FLEN-1:`H_LEN] ? Y[`H_LEN-1:0] : {1'b0, {`H_NE+1{1'b1}}, (`H_NF-1)'(0)};
        assign ZLen3 = &Z[`FLEN-1:`H_LEN] ? Z[`H_LEN-1:0] : {1'b0, {`H_NE+1{1'b1}}, (`H_NF-1)'(0)}; 

        always_comb begin
            case (FmtE)
                2'b11: begin
                    assign XSgnE = X[`FLEN-1];
                    assign YSgnE = Y[`FLEN-1];
                    assign ZSgnE = Z[`FLEN-1];

                    assign XExpE = X[`FLEN-2:`NF]; 
                    assign YExpE = Y[`FLEN-2:`NF]; 
                    assign ZExpE = Z[`FLEN-2:`NF]; 

                    assign XFracE = X[`NF-1:0];
                    assign YFracE = Y[`NF-1:0];
                    assign ZFracE = Z[`NF-1:0];

                    assign XExpNonzero = |X[`FLEN-2:`NF]; 
                    assign YExpNonzero = |Y[`FLEN-2:`NF];
                    assign ZExpNonzero = |Z[`FLEN-2:`NF];

                    assign XExpMaxE = &X[`FLEN-2:`NF];
                    assign YExpMaxE = &Y[`FLEN-2:`NF];
                    assign ZExpMaxE = &Z[`FLEN-2:`NF];
                end
                2'b01: begin
                    assign XSgnE = XLen1[`LEN1-1];
                    assign YSgnE = YLen1[`LEN1-1];
                    assign ZSgnE = ZLen1[`LEN1-1];

                    // example double to single conversion:
                    // 1023 = 0011 1111 1111
                    // 127  = 0000 0111 1111 (subtract this)
                    // 896  = 0011 1000 0000
                    // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
                    // dexp = 0bdd dbbb bbbb 
                    // also need to take into account possible zero/denorm/inf/NaN values
                    assign XExpE = {XLen1[`D_LEN-2], {`NE-`D_NE{~XLen1[`D_LEN-2]&~XExpZero|XExpMaxE}}, XLen1[`D_LEN-3:`D_NF]}; 
                    assign YExpE = {YLen1[`D_LEN-2], {`NE-`D_NE{~YLen1[`D_LEN-2]&~YExpZero|YExpMaxE}}, YLen1[`D_LEN-3:`D_NF]}; 
                    assign ZExpE = {ZLen1[`D_LEN-2], {`NE-`D_NE{~ZLen1[`D_LEN-2]&~ZExpZero|ZExpMaxE}}, ZLen1[`D_LEN-3:`D_NF]}; 

                    assign XFracE = {XLen1[`D_NE-1:0], (`NF-`D_NE)'(0)};
                    assign YFracE = {YLen1[`D_NE-1:0], (`NF-`D_NE)'(0)};
                    assign ZFracE = {ZLen1[`D_NE-1:0], (`NF-`D_NE)'(0)};

                    assign XExpNonzero = |XLen1[`D_LEN-2:`D_NE]; 
                    assign YExpNonzero = |YLen1[`D_LEN-2:`D_NE];
                    assign ZExpNonzero = |ZLen1[`D_LEN-2:`D_NE];

                    assign XExpMaxE = &XLen1[`D_LEN-2:`D_NE];
                    assign YExpMaxE = &YLen1[`D_LEN-2:`D_NE];
                    assign ZExpMaxE = &ZLen1[`D_LEN-2:`D_NE];
                end
                2'b00: begin
                    assign XSgnE = XLen2[`S_LEN-1];
                    assign YSgnE = YLen2[`S_LEN-1];
                    assign ZSgnE = ZLen2[`S_LEN-1];

                    // example double to single conversion:
                    // 1023 = 0011 1111 1111
                    // 127  = 0000 0111 1111 (subtract this)
                    // 896  = 0011 1000 0000
                    // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
                    // dexp = 0bdd dbbb bbbb 
                    // also need to take into account possible zero/denorm/inf/NaN values
                    assign XExpE = {XLen2[`S_LEN-2], {`NE-`S_NE{~XLen2[`S_LEN-2]&~XExpZero|XExpMaxE}}, XLen2[`S_LEN-3:`S_NF]}; 
                    assign YExpE = {YLen2[`S_LEN-2], {`NE-`S_NE{~YLen2[`S_LEN-2]&~YExpZero|YExpMaxE}}, YLen2[`S_LEN-3:`S_NF]}; 
                    assign ZExpE = {ZLen2[`S_LEN-2], {`NE-`S_NE{~ZLen2[`S_LEN-2]&~ZExpZero|ZExpMaxE}}, ZLen2[`S_LEN-3:`S_NF]}; 

                    assign XFracE = {XLen2[`S_NF-1:0], (`NF-`S_NF)'(0)};
                    assign YFracE = {YLen2[`S_NF-1:0], (`NF-`S_NF)'(0)};
                    assign ZFracE = {ZLen2[`S_NF-1:0], (`NF-`S_NF)'(0)};

                    assign XExpNonzero = |XLen2[`S_LEN-2:`S_NF]; 
                    assign YExpNonzero = |YLen2[`S_LEN-2:`S_NF];
                    assign ZExpNonzero = |ZLen2[`S_LEN-2:`S_NF];

                    assign XExpMaxE = &XLen2[`S_LEN-2:`S_NF];
                    assign YExpMaxE = &YLen2[`S_LEN-2:`S_NF];
                    assign ZExpMaxE = &ZLen2[`S_LEN-2:`S_NF];
                end
                2'b10: begin
                    assign XSgnE = XLen3[`H_LEN-1];
                    assign YSgnE = YLen3[`H_LEN-1];
                    assign ZSgnE = ZLen3[`H_LEN-1];

                    // example double to single conversion:
                    // 1023 = 0011 1111 1111
                    // 127  = 0000 0111 1111 (subtract this)
                    // 896  = 0011 1000 0000
                    // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
                    // dexp = 0bdd dbbb bbbb 
                    // also need to take into account possible zero/denorm/inf/NaN values
                    assign XExpE = {XLen3[`H_LEN-2], {`NE-`H_NE{~XLen3[`H_LEN-2]&~XExpZero|XExpMaxE}}, XLen3[`H_LEN-3:`H_NF]}; 
                    assign YExpE = {YLen3[`H_LEN-2], {`NE-`H_NE{~YLen3[`H_LEN-2]&~YExpZero|YExpMaxE}}, YLen3[`H_LEN-3:`H_NF]}; 
                    assign ZExpE = {ZLen3[`H_LEN-2], {`NE-`H_NE{~ZLen3[`H_LEN-2]&~ZExpZero|ZExpMaxE}}, ZLen3[`H_LEN-3:`H_NF]}; 

                    assign XFracE = {XLen3[`H_NF-1:0], (`NF-`H_NF)'(0)};
                    assign YFracE = {YLen3[`H_NF-1:0], (`NF-`H_NF)'(0)};
                    assign ZFracE = {ZLen3[`H_NF-1:0], (`NF-`H_NF)'(0)};

                    assign XExpNonzero = |XLen3[`H_LEN-2:`H_NF]; 
                    assign YExpNonzero = |YLen3[`H_LEN-2:`H_NF];
                    assign ZExpNonzero = |ZLen3[`H_LEN-2:`H_NF];

                    assign XExpMaxE = &XLen3[`H_LEN-2:`H_NF];
                    assign YExpMaxE = &YLen3[`H_LEN-2:`H_NF];
                    assign ZExpMaxE = &ZLen3[`H_LEN-2:`H_NF];
                end
            endcase
        end

    end

    assign XExpZero = ~XExpNonzero;
    assign YExpZero = ~YExpNonzero;
    assign ZExpZero = ~ZExpNonzero;

    assign XFracZero = ~|XFracE;
    assign YFracZero = ~|YFracE;
    assign ZFracZero = ~|ZFracE;

    assign XManE = {XExpNonzero, XFracE};
    assign YManE = {YExpNonzero, YFracE};
    assign ZManE = {ZExpNonzero, ZFracE};

    assign XNormE = ~(XExpMaxE|XExpZero);
    
    // force single precision input to be a NaN if it isn't properly Nan Boxed
    assign XNaNE = XExpMaxE & ~XFracZero;
    assign YNaNE = YExpMaxE & ~YFracZero;
    assign ZNaNE = ZExpMaxE & ~ZFracZero;

    assign XSNaNE = XNaNE&~XFracE[`NF-1];
    assign YSNaNE = YNaNE&~YFracE[`NF-1];
    assign ZSNaNE = ZNaNE&~ZFracE[`NF-1];

    assign XDenormE = XExpZero & ~XFracZero;
    assign YDenormE = YExpZero & ~YFracZero;
    assign ZDenormE = ZExpZero & ~ZFracZero;

    assign XInfE = XExpMaxE & XFracZero;
    assign YInfE = YExpMaxE & YFracZero;
    assign ZInfE = ZExpMaxE & ZFracZero;

    assign XZeroE = XExpZero & XFracZero;
    assign YZeroE = YExpZero & YFracZero;
    assign ZZeroE = ZExpZero & ZFracZero;
    
endmodule
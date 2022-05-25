`include "wally-config.vh"

module unpack ( 
    input logic  [`FLEN-1:0]        X, Y, Z,    // inputs from register file
    input logic  [`FPSIZES/3:0]     FmtE,       // format signal 00 - single 01 - double 11 - quad 10 - half
    output logic                    XSgnE, YSgnE, ZSgnE,    // sign bits of XYZ
    output logic [`NE-1:0]          XExpE, YExpE, ZExpE,    // exponents of XYZ (converted to largest supported precision)
    output logic [`NF:0]            XManE, YManE, ZManE,    // mantissas of XYZ (converted to largest supported precision)
    output logic                    XNormE,                 // is X a normalized number
    output logic                    XNaNE, YNaNE, ZNaNE,    // is XYZ a NaN
    output logic                    XSNaNE, YSNaNE, ZSNaNE, // is XYZ a signaling NaN
    output logic                    XDenormE, YDenormE, ZDenormE,   // is XYZ denormalized
    output logic                    XZeroE, YZeroE, ZZeroE,         // is XYZ zero
    output logic                    XInfE, YInfE, ZInfE,            // is XYZ infinity
    output logic                    XOrigDenormE, ZOrigDenormE,     // is the original precision denormalized
    output logic                    XExpMaxE                        // does X have the maximum exponent (NaN or Inf)
);
 
    logic [`NF-1:0] XFracE, YFracE, ZFracE; //Fraction of XYZ
    logic           XExpNonzero, YExpNonzero, ZExpNonzero; // is the exponent of XYZ non-zero
    logic           XFracZero, YFracZero, ZFracZero; // is the fraction zero
    logic           XExpZero, YExpZero, ZExpZero; // is the exponent zero
    logic           YExpMaxE, ZExpMaxE;  // is the exponent all 1s
    
    if (`FPSIZES == 1) begin        // if there is only one floating point format supported

        // sign bit
        assign XSgnE = X[`FLEN-1];
        assign YSgnE = Y[`FLEN-1];
        assign ZSgnE = Z[`FLEN-1];

        // exponent
        assign XExpE = X[`FLEN-2:`NF]; 
        assign YExpE = Y[`FLEN-2:`NF]; 
        assign ZExpE = Z[`FLEN-2:`NF]; 

        // fraction (no assumed 1)
        assign XFracE = X[`NF-1:0];
        assign YFracE = Y[`NF-1:0];
        assign ZFracE = Z[`NF-1:0];

        // is the exponent non-zero
        assign XExpNonzero = |XExpE; 
        assign YExpNonzero = |YExpE;
        assign ZExpNonzero = |ZExpE;

        // is the exponent all 1's
        assign XExpMaxE = &XExpE;
        assign YExpMaxE = &YExpE;
        assign ZExpMaxE = &ZExpE;

        assign XOrigDenormE = 1'b0;
        assign ZOrigDenormE = 1'b0;
    

    end else if (`FPSIZES == 2) begin   // if there are 2 floating point formats supported
        //***need better names for these constants
        // largest format | smaller format
        //----------------------------------
        //      `FLEN     |     `LEN1       length of floating point number
        //      `NE       |     `NE1        length of exponent
        //      `NF       |     `NF1        length of fraction
        //      `BIAS     |     `BIAS1      exponent's bias value
        //      `FMT      |     `FMT1       precision's format value - Q=11 D=01 S=00 H=10

        // Possible combinantions specified by spec:
        //      double and single
        //      single and half

        // Not needed but can also handle:
        //      quad   and double
        //      quad   and single
        //      quad   and half
        //      double and half

        logic  [`LEN1-1:0]  XLen1, YLen1, ZLen1; // Remove NaN boxing or NaN, if not properly NaN boxed
        logic               YOrigDenormE;   // the original value of XYZ is denormalized

        // Check NaN boxing, If the value is not properly NaN boxed, set the value to a quiet NaN
        assign XLen1 = &X[`FLEN-1:`LEN1] ? X[`LEN1-1:0] : {1'b0, {`NE1+1{1'b1}}, (`NF1-1)'(0)};
        assign YLen1 = &Y[`FLEN-1:`LEN1] ? Y[`LEN1-1:0] : {1'b0, {`NE1+1{1'b1}}, (`NF1-1)'(0)};
        assign ZLen1 = &Z[`FLEN-1:`LEN1] ? Z[`LEN1-1:0] : {1'b0, {`NE1+1{1'b1}}, (`NF1-1)'(0)};  

        // choose sign bit depending on format - 1=larger precsion 0=smaller precision
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

        // extract the exponent, converting the smaller exponent into the larger precision if nessisary
        //      - if the original precision had a denormal number convert the exponent value 1
        assign XExpE = FmtE ? X[`FLEN-2:`NF] : XOrigDenormE ? {1'b0, {`NE-`NE1{1'b1}}, (`NE1-1)'(1)} : {XLen1[`LEN1-2], {`NE-`NE1{~XLen1[`LEN1-2]&~XExpZero|XExpMaxE}}, XLen1[`LEN1-3:`NF1]}; 
        assign YExpE = FmtE ? Y[`FLEN-2:`NF] : YOrigDenormE ? {1'b0, {`NE-`NE1{1'b1}}, (`NE1-1)'(1)} : {YLen1[`LEN1-2], {`NE-`NE1{~YLen1[`LEN1-2]&~YExpZero|YExpMaxE}}, YLen1[`LEN1-3:`NF1]}; 
        assign ZExpE = FmtE ? Z[`FLEN-2:`NF] : ZOrigDenormE ? {1'b0, {`NE-`NE1{1'b1}}, (`NE1-1)'(1)} : {ZLen1[`LEN1-2], {`NE-`NE1{~ZLen1[`LEN1-2]&~ZExpZero|ZExpMaxE}}, ZLen1[`LEN1-3:`NF1]}; 

        // is the input (in it's original format) denormalized
        assign XOrigDenormE = FmtE ? 0 : ~|XLen1[`LEN1-2:`NF1] & ~XFracZero; 
        assign YOrigDenormE = FmtE ? 0 : ~|YLen1[`LEN1-2:`NF1] & ~YFracZero; 
        assign ZOrigDenormE = FmtE ? 0 : ~|ZLen1[`LEN1-2:`NF1] & ~ZFracZero; 

        // extract the fraction, add trailing zeroes to the mantissa if nessisary
        assign XFracE = FmtE ? X[`NF-1:0] : {XLen1[`NF1-1:0], (`NF-`NF1)'(0)};
        assign YFracE = FmtE ? Y[`NF-1:0] : {YLen1[`NF1-1:0], (`NF-`NF1)'(0)};
        assign ZFracE = FmtE ? Z[`NF-1:0] : {ZLen1[`NF1-1:0], (`NF-`NF1)'(0)};

        // is the exponent non-zero
        assign XExpNonzero = FmtE ? |X[`FLEN-2:`NF] : |XLen1[`LEN1-2:`NF1]; 
        assign YExpNonzero = FmtE ? |Y[`FLEN-2:`NF] : |YLen1[`LEN1-2:`NF1];
        assign ZExpNonzero = FmtE ? |Z[`FLEN-2:`NF] : |ZLen1[`LEN1-2:`NF1];

        // is the exponent all 1's
        assign XExpMaxE = FmtE ? &X[`FLEN-2:`NF] : &XLen1[`LEN1-2:`NF1];
        assign YExpMaxE = FmtE ? &Y[`FLEN-2:`NF] : &YLen1[`LEN1-2:`NF1];
        assign ZExpMaxE = FmtE ? &Z[`FLEN-2:`NF] : &ZLen1[`LEN1-2:`NF1];
    

    end else if (`FPSIZES == 3) begin       // three floating point precsions supported

        //***need better names for these constants
        // largest format | larger format  | smallest format
        //---------------------------------------------------
        //      `FLEN     |     `LEN1      |    `LEN2       length of floating point number
        //      `NE       |     `NE1       |    `NE2        length of exponent
        //      `NF       |     `NF1       |    `NF2        length of fraction
        //      `BIAS     |     `BIAS1     |    `BIAS2      exponent's bias value
        //      `FMT      |     `FMT1      |    `FMT2       precision's format value - Q=11 D=01 S=00 H=10

        // Possible combinantions specified by spec:
        //      quad   and double and single
        //      double and single and half

        // Not needed but can also handle:
        //      quad   and double and half
        //      quad   and single and half

        logic  [`LEN1-1:0]  XLen1, YLen1, ZLen1; // Remove NaN boxing or NaN, if not properly NaN boxed for larger percision
        logic  [`LEN2-1:0]  XLen2, YLen2, ZLen2; // Remove NaN boxing or NaN, if not properly NaN boxed for smallest precision
        logic               YOrigDenormE;   // the original value of XYZ is denormalized
        
        // Check NaN boxing, If the value is not properly NaN boxed, set the value to a quiet NaN - for larger precision
        assign XLen1 = &X[`FLEN-1:`LEN1] ? X[`LEN1-1:0] : {1'b0, {`NE1+1{1'b1}}, (`NF1-1)'(0)};
        assign YLen1 = &Y[`FLEN-1:`LEN1] ? Y[`LEN1-1:0] : {1'b0, {`NE1+1{1'b1}}, (`NF1-1)'(0)};
        assign ZLen1 = &Z[`FLEN-1:`LEN1] ? Z[`LEN1-1:0] : {1'b0, {`NE1+1{1'b1}}, (`NF1-1)'(0)}; 

        // Check NaN boxing, If the value is not properly NaN boxed, set the value to a quiet NaN - for smaller precision
        assign XLen2 = &X[`FLEN-1:`LEN2] ? X[`LEN2-1:0] : {1'b0, {`NE2+1{1'b1}}, (`NF2-1)'(0)};
        assign YLen2 = &Y[`FLEN-1:`LEN2] ? Y[`LEN2-1:0] : {1'b0, {`NE2+1{1'b1}}, (`NF2-1)'(0)};
        assign ZLen2 = &Z[`FLEN-1:`LEN2] ? Z[`LEN2-1:0] : {1'b0, {`NE2+1{1'b1}}, (`NF2-1)'(0)}; 

        // There are 2 case statements
        //      - one for other singals and one for sgn/exp/frac
        //      - need two for the dependencies in the expoenent calculation
        always_comb begin
            case (FmtE)
                `FMT: begin // if input is largest precision (`FLEN - ie quad or double)

                    // This is the original format so set OrigDenorm to 0
                    XOrigDenormE = 1'b0; 
                    YOrigDenormE = 1'b0; 
                    ZOrigDenormE = 1'b0; 

                    // is the exponent non-zero
                    XExpNonzero = |X[`FLEN-2:`NF]; 
                    YExpNonzero = |Y[`FLEN-2:`NF];
                    ZExpNonzero = |Z[`FLEN-2:`NF];

                    // is the exponent all 1's
                    XExpMaxE = &X[`FLEN-2:`NF];
                    YExpMaxE = &Y[`FLEN-2:`NF];
                    ZExpMaxE = &Z[`FLEN-2:`NF];
                end
                `FMT1: begin    // if input is larger precsion (`LEN1 - double or single)

                    // is the input (in it's original format) denormalized
                    XOrigDenormE = ~|XLen1[`LEN1-2:`NF1] & ~XFracZero; 
                    YOrigDenormE = ~|YLen1[`LEN1-2:`NF1] & ~YFracZero; 
                    ZOrigDenormE = ~|ZLen1[`LEN1-2:`NF1] & ~ZFracZero; 

                    // is the exponent non-zero
                    XExpNonzero = |XLen1[`LEN1-2:`NF1]; 
                    YExpNonzero = |YLen1[`LEN1-2:`NF1];
                    ZExpNonzero = |ZLen1[`LEN1-2:`NF1];

                    // is the exponent all 1's
                    XExpMaxE = &XLen1[`LEN1-2:`NF1];
                    YExpMaxE = &YLen1[`LEN1-2:`NF1];
                    ZExpMaxE = &ZLen1[`LEN1-2:`NF1];
                end
                `FMT2: begin        // if input is smallest precsion (`LEN2 - single or half)

                    // is the input (in it's original format) denormalized
                    XOrigDenormE = ~|XLen2[`LEN2-2:`NF2] & ~XFracZero; 
                    YOrigDenormE = ~|YLen2[`LEN2-2:`NF2] & ~YFracZero; 
                    ZOrigDenormE = ~|ZLen2[`LEN2-2:`NF2] & ~ZFracZero; 

                    // is the exponent non-zero
                    XExpNonzero = |XLen2[`LEN2-2:`NF2]; 
                    YExpNonzero = |YLen2[`LEN2-2:`NF2];
                    ZExpNonzero = |ZLen2[`LEN2-2:`NF2];

                    // is the exponent all 1's
                    XExpMaxE = &XLen2[`LEN2-2:`NF2];
                    YExpMaxE = &YLen2[`LEN2-2:`NF2];
                    ZExpMaxE = &ZLen2[`LEN2-2:`NF2];
                end
                default: begin
                    XOrigDenormE = 0; 
                    YOrigDenormE = 0; 
                    ZOrigDenormE = 0; 
                    XExpNonzero = 0; 
                    YExpNonzero = 0;
                    ZExpNonzero = 0;
                    XExpMaxE = 0;
                    YExpMaxE = 0;
                    ZExpMaxE = 0;
                end
            endcase
        end
        always_comb begin
            case (FmtE)
                `FMT: begin // if input is largest precision (`FLEN - ie quad or double)
                    // extract the sign bit
                    XSgnE = X[`FLEN-1];
                    YSgnE = Y[`FLEN-1];
                    ZSgnE = Z[`FLEN-1];

                    // extract the exponent
                    XExpE = X[`FLEN-2:`NF]; 
                    YExpE = Y[`FLEN-2:`NF]; 
                    ZExpE = Z[`FLEN-2:`NF]; 

                    // extract the fraction
                    XFracE = X[`NF-1:0];
                    YFracE = Y[`NF-1:0];
                    ZFracE = Z[`NF-1:0];
                end
                `FMT1: begin    // if input is larger precsion (`LEN1 - double or single)

                    // extract the sign bit
                    XSgnE = XLen1[`LEN1-1];
                    YSgnE = YLen1[`LEN1-1];
                    ZSgnE = ZLen1[`LEN1-1];

                    // example double to single conversion:
                    // 1023 = 0011 1111 1111
                    // 127  = 0000 0111 1111 (subtract this)
                    // 896  = 0011 1000 0000
                    // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
                    // dexp = 0bdd dbbb bbbb 
                    // also need to take into account possible zero/denorm/inf/NaN values

                    // convert the larger precision's exponent to use the largest precision's bias
                    XExpE = XOrigDenormE ? {1'b0, {`NE-`NE1{1'b1}}, (`NE1-1)'(1)} : {XLen1[`LEN1-2], {`NE-`NE1{~XLen1[`LEN1-2]&~XExpZero|XExpMaxE}}, XLen1[`LEN1-3:`NF1]}; 
                    YExpE = YOrigDenormE ? {1'b0, {`NE-`NE1{1'b1}}, (`NE1-1)'(1)} : {YLen1[`LEN1-2], {`NE-`NE1{~YLen1[`LEN1-2]&~YExpZero|YExpMaxE}}, YLen1[`LEN1-3:`NF1]}; 
                    ZExpE = ZOrigDenormE ? {1'b0, {`NE-`NE1{1'b1}}, (`NE1-1)'(1)} : {ZLen1[`LEN1-2], {`NE-`NE1{~ZLen1[`LEN1-2]&~ZExpZero|ZExpMaxE}}, ZLen1[`LEN1-3:`NF1]}; 

                    // extract the fraction and add the nessesary trailing zeros
                    XFracE = {XLen1[`NF1-1:0], (`NF-`NF1)'(0)};
                    YFracE = {YLen1[`NF1-1:0], (`NF-`NF1)'(0)};
                    ZFracE = {ZLen1[`NF1-1:0], (`NF-`NF1)'(0)};
                end
                `FMT2: begin        // if input is smallest precsion (`LEN2 - single or half)

                    // exctract the sign bit
                    XSgnE = XLen2[`LEN2-1];
                    YSgnE = YLen2[`LEN2-1];
                    ZSgnE = ZLen2[`LEN2-1];

                    // example double to single conversion:
                    // 1023 = 0011 1111 1111
                    // 127  = 0000 0111 1111 (subtract this)
                    // 896  = 0011 1000 0000
                    // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
                    // dexp = 0bdd dbbb bbbb 
                    // also need to take into account possible zero/denorm/inf/NaN values
                    
                    // convert the smallest precision's exponent to use the largest precision's bias
                    XExpE = XOrigDenormE ? {1'b0, {`NE-`NE2{1'b1}}, (`NE2-1)'(1)} : {XLen2[`LEN2-2], {`NE-`NE2{~XLen2[`LEN2-2]&~XExpZero|XExpMaxE}}, XLen2[`LEN2-3:`NF2]}; 
                    YExpE = YOrigDenormE ? {1'b0, {`NE-`NE2{1'b1}}, (`NE2-1)'(1)} : {YLen2[`LEN2-2], {`NE-`NE2{~YLen2[`LEN2-2]&~YExpZero|YExpMaxE}}, YLen2[`LEN2-3:`NF2]}; 
                    ZExpE = ZOrigDenormE ? {1'b0, {`NE-`NE2{1'b1}}, (`NE2-1)'(1)} : {ZLen2[`LEN2-2], {`NE-`NE2{~ZLen2[`LEN2-2]&~ZExpZero|ZExpMaxE}}, ZLen2[`LEN2-3:`NF2]}; 

                    // extract the fraction and add the nessesary trailing zeros
                    XFracE = {XLen2[`NF2-1:0], (`NF-`NF2)'(0)};
                    YFracE = {YLen2[`NF2-1:0], (`NF-`NF2)'(0)};
                    ZFracE = {ZLen2[`NF2-1:0], (`NF-`NF2)'(0)};
                end
                default: begin
                    XSgnE = 0;
                    YSgnE = 0;
                    ZSgnE = 0;
                    XExpE = 0; 
                    YExpE = 0;
                    ZExpE = 0; 
                    XFracE = 0;
                    YFracE = 0;
                    ZFracE = 0;
                end
            endcase
        end

    end else if (`FPSIZES == 4) begin      // if all precsisons are supported - quad, double, single, and half
    
        //    quad   |  double  |  single  |  half    
        //-------------------------------------------------------------------
        //   `Q_LEN  |  `D_LEN  |  `S_LEN  |  `H_LEN     length of floating point number
        //   `Q_NE   |  `D_NE   |  `S_NE   |  `H_NE      length of exponent
        //   `Q_NF   |  `D_NF   |  `S_NF   |  `H_NF      length of fraction
        //   `Q_BIAS |  `D_BIAS |  `S_BIAS |  `H_BIAS    exponent's bias value
        //   `Q_FMT  |  `D_FMT  |  `S_FMT  |  `H_FMT     precision's format value - Q=11 D=01 S=00 H=10


        logic  [`D_LEN-1:0]  XLen1, YLen1, ZLen1; // Remove NaN boxing or NaN, if not properly NaN boxed for double percision
        logic  [`S_LEN-1:0]  XLen2, YLen2, ZLen2; // Remove NaN boxing or NaN, if not properly NaN boxed for single percision
        logic  [`H_LEN-1:0]  XLen3, YLen3, ZLen3; // Remove NaN boxing or NaN, if not properly NaN boxed for half percision
        logic                YOrigDenormE;   // the original value of XYZ is denormalized
        
        // Check NaN boxing, If the value is not properly NaN boxed, set the value to a quiet NaN - for double precision
        assign XLen1 = &X[`Q_LEN-1:`D_LEN] ? X[`D_LEN-1:0] : {1'b0, {`D_NE+1{1'b1}}, (`D_NF-1)'(0)};
        assign YLen1 = &Y[`Q_LEN-1:`D_LEN] ? Y[`D_LEN-1:0] : {1'b0, {`D_NE+1{1'b1}}, (`D_NF-1)'(0)};
        assign ZLen1 = &Z[`Q_LEN-1:`D_LEN] ? Z[`D_LEN-1:0] : {1'b0, {`D_NE+1{1'b1}}, (`D_NF-1)'(0)}; 

        // Check NaN boxing, If the value is not properly NaN boxed, set the value to a quiet NaN - for single precision
        assign XLen2 = &X[`Q_LEN-1:`S_LEN] ? X[`S_LEN-1:0] : {1'b0, {`S_NE+1{1'b1}}, (`S_NF-1)'(0)};
        assign YLen2 = &Y[`Q_LEN-1:`S_LEN] ? Y[`S_LEN-1:0] : {1'b0, {`S_NE+1{1'b1}}, (`S_NF-1)'(0)};
        assign ZLen2 = &Z[`Q_LEN-1:`S_LEN] ? Z[`S_LEN-1:0] : {1'b0, {`S_NE+1{1'b1}}, (`S_NF-1)'(0)}; 

        // Check NaN boxing, If the value is not properly NaN boxed, set the value to a quiet NaN - for half precision
        assign XLen3 = &X[`Q_LEN-1:`H_LEN] ? X[`H_LEN-1:0] : {1'b0, {`H_NE+1{1'b1}}, (`H_NF-1)'(0)};
        assign YLen3 = &Y[`Q_LEN-1:`H_LEN] ? Y[`H_LEN-1:0] : {1'b0, {`H_NE+1{1'b1}}, (`H_NF-1)'(0)};
        assign ZLen3 = &Z[`Q_LEN-1:`H_LEN] ? Z[`H_LEN-1:0] : {1'b0, {`H_NE+1{1'b1}}, (`H_NF-1)'(0)}; 


        // There are 2 case statements
        //      - one for other singals and one for sgn/exp/frac
        //      - need two for the dependencies in the expoenent calculation
        always_comb begin
            case (FmtE)
                2'b11: begin  // if input is quad percision

                    // This is the original format so set OrigDenorm to 0
                    XOrigDenormE = 1'b0; 
                    YOrigDenormE = 1'b0; 
                    ZOrigDenormE = 1'b0; 

                    // is the exponent non-zero
                    XExpNonzero = |X[`Q_LEN-2:`Q_NF]; 
                    YExpNonzero = |Y[`Q_LEN-2:`Q_NF];
                    ZExpNonzero = |Z[`Q_LEN-2:`Q_NF];

                    // is the exponent all 1's
                    XExpMaxE = &X[`Q_LEN-2:`Q_NF];
                    YExpMaxE = &Y[`Q_LEN-2:`Q_NF];
                    ZExpMaxE = &Z[`Q_LEN-2:`Q_NF];
                end
                2'b01: begin  // if input is double percision

                    // is the exponent all 1's
                    XExpMaxE = &XLen1[`D_LEN-2:`D_NF];
                    YExpMaxE = &YLen1[`D_LEN-2:`D_NF];
                    ZExpMaxE = &ZLen1[`D_LEN-2:`D_NF];

                    // is the input (in it's original format) denormalized
                    XOrigDenormE = ~|XLen1[`D_LEN-2:`D_NF] & ~XFracZero; 
                    YOrigDenormE = ~|YLen1[`D_LEN-2:`D_NF] & ~YFracZero; 
                    ZOrigDenormE = ~|ZLen1[`D_LEN-2:`D_NF] & ~ZFracZero; 

                    // is the exponent non-zero
                    XExpNonzero = |XLen1[`D_LEN-2:`D_NF]; 
                    YExpNonzero = |YLen1[`D_LEN-2:`D_NF];
                    ZExpNonzero = |ZLen1[`D_LEN-2:`D_NF];
                end
                2'b00: begin      // if input is single percision

                    // is the exponent all 1's
                    XExpMaxE = &XLen2[`S_LEN-2:`S_NF];
                    YExpMaxE = &YLen2[`S_LEN-2:`S_NF];
                    ZExpMaxE = &ZLen2[`S_LEN-2:`S_NF];

                    // is the input (in it's original format) denormalized
                    XOrigDenormE = ~|XLen2[`S_LEN-2:`S_NF] & ~XFracZero; 
                    YOrigDenormE = ~|YLen2[`S_LEN-2:`S_NF] & ~YFracZero; 
                    ZOrigDenormE = ~|ZLen2[`S_LEN-2:`S_NF] & ~ZFracZero; 

                    // is the exponent non-zero
                    XExpNonzero = |XLen2[`S_LEN-2:`S_NF]; 
                    YExpNonzero = |YLen2[`S_LEN-2:`S_NF];
                    ZExpNonzero = |ZLen2[`S_LEN-2:`S_NF];
                end
                2'b10: begin      // if input is half percision

                    // is the exponent all 1's
                    XExpMaxE = &XLen3[`H_LEN-2:`H_NF];
                    YExpMaxE = &YLen3[`H_LEN-2:`H_NF];
                    ZExpMaxE = &ZLen3[`H_LEN-2:`H_NF];

                    // is the input (in it's original format) denormalized
                    XOrigDenormE = ~|XLen3[`H_LEN-2:`H_NF] & ~XFracZero; 
                    YOrigDenormE = ~|YLen3[`H_LEN-2:`H_NF] & ~YFracZero; 
                    ZOrigDenormE = ~|ZLen3[`H_LEN-2:`H_NF] & ~ZFracZero; 

                    // is the exponent non-zero
                    XExpNonzero = |XLen3[`H_LEN-2:`H_NF]; 
                    YExpNonzero = |YLen3[`H_LEN-2:`H_NF];
                    ZExpNonzero = |ZLen3[`H_LEN-2:`H_NF];
                end
            endcase
        end

        always_comb begin
            case (FmtE)
                2'b11: begin  // if input is quad percision
                    // extract sign bit
                    XSgnE = X[`Q_LEN-1];
                    YSgnE = Y[`Q_LEN-1];
                    ZSgnE = Z[`Q_LEN-1];

                    // extract the exponent
                    XExpE = X[`Q_LEN-2:`Q_NF]; 
                    YExpE = Y[`Q_LEN-2:`Q_NF]; 
                    ZExpE = Z[`Q_LEN-2:`Q_NF]; 

                    // extract the fraction
                    XFracE = X[`Q_NF-1:0];
                    YFracE = Y[`Q_NF-1:0];
                    ZFracE = Z[`Q_NF-1:0];
                end
                2'b01: begin  // if input is double percision
                    // extract sign bit
                    XSgnE = XLen1[`D_LEN-1];
                    YSgnE = YLen1[`D_LEN-1];
                    ZSgnE = ZLen1[`D_LEN-1];

                    // example double to single conversion:
                    // 1023 = 0011 1111 1111
                    // 127  = 0000 0111 1111 (subtract this)
                    // 896  = 0011 1000 0000
                    // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
                    // dexp = 0bdd dbbb bbbb 
                    // also need to take into account possible zero/denorm/inf/NaN values
                    
                    // convert the double precsion exponent into quad precsion

                    XExpE = XOrigDenormE ? {1'b0, {`Q_NE-`D_NE{1'b1}}, (`D_NE-1)'(1)} : {XLen1[`D_LEN-2], {`Q_NE-`D_NE{~XLen1[`D_LEN-2]&~XExpZero|XExpMaxE}}, XLen1[`D_LEN-3:`D_NF]}; 
                    YExpE = YOrigDenormE ? {1'b0, {`Q_NE-`D_NE{1'b1}}, (`D_NE-1)'(1)} : {YLen1[`D_LEN-2], {`Q_NE-`D_NE{~YLen1[`D_LEN-2]&~YExpZero|YExpMaxE}}, YLen1[`D_LEN-3:`D_NF]}; 
                    ZExpE = ZOrigDenormE ? {1'b0, {`Q_NE-`D_NE{1'b1}}, (`D_NE-1)'(1)} : {ZLen1[`D_LEN-2], {`Q_NE-`D_NE{~ZLen1[`D_LEN-2]&~ZExpZero|ZExpMaxE}}, ZLen1[`D_LEN-3:`D_NF]}; 

                    // extract the fraction and add the nessesary trailing zeros
                    XFracE = {XLen1[`D_NF-1:0], (`Q_NF-`D_NF)'(0)};
                    YFracE = {YLen1[`D_NF-1:0], (`Q_NF-`D_NF)'(0)};
                    ZFracE = {ZLen1[`D_NF-1:0], (`Q_NF-`D_NF)'(0)};
                end
                2'b00: begin      // if input is single percision
                    // extract sign bit
                    XSgnE = XLen2[`S_LEN-1];
                    YSgnE = YLen2[`S_LEN-1];
                    ZSgnE = ZLen2[`S_LEN-1];

                    // example double to single conversion:
                    // 1023 = 0011 1111 1111
                    // 127  = 0000 0111 1111 (subtract this)
                    // 896  = 0011 1000 0000
                    // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
                    // dexp = 0bdd dbbb bbbb 
                    // also need to take into account possible zero/denorm/inf/NaN values
                    
                    // convert the single precsion exponent into quad precsion
                    XExpE = XOrigDenormE ? {1'b0, {`Q_NE-`S_NE{1'b1}}, (`S_NE-1)'(1)} : {XLen2[`S_LEN-2], {`Q_NE-`S_NE{~XLen2[`S_LEN-2]&~XExpZero|XExpMaxE}}, XLen2[`S_LEN-3:`S_NF]}; 
                    YExpE = YOrigDenormE ? {1'b0, {`Q_NE-`S_NE{1'b1}}, (`S_NE-1)'(1)} : {YLen2[`S_LEN-2], {`Q_NE-`S_NE{~YLen2[`S_LEN-2]&~YExpZero|YExpMaxE}}, YLen2[`S_LEN-3:`S_NF]}; 
                    ZExpE = ZOrigDenormE ? {1'b0, {`Q_NE-`S_NE{1'b1}}, (`S_NE-1)'(1)} : {ZLen2[`S_LEN-2], {`Q_NE-`S_NE{~ZLen2[`S_LEN-2]&~ZExpZero|ZExpMaxE}}, ZLen2[`S_LEN-3:`S_NF]}; 

                    // extract the fraction and add the nessesary trailing zeros
                    XFracE = {XLen2[`S_NF-1:0], (`Q_NF-`S_NF)'(0)};
                    YFracE = {YLen2[`S_NF-1:0], (`Q_NF-`S_NF)'(0)};
                    ZFracE = {ZLen2[`S_NF-1:0], (`Q_NF-`S_NF)'(0)};
                end
                2'b10: begin      // if input is half percision
                    // extract sign bit
                    XSgnE = XLen3[`H_LEN-1];
                    YSgnE = YLen3[`H_LEN-1];
                    ZSgnE = ZLen3[`H_LEN-1];

                    // example double to single conversion:
                    // 1023 = 0011 1111 1111
                    // 127  = 0000 0111 1111 (subtract this)
                    // 896  = 0011 1000 0000
                    // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
                    // dexp = 0bdd dbbb bbbb 
                    // also need to take into account possible zero/denorm/inf/NaN values

                    // convert the half precsion exponent into quad precsion
                    XExpE = XOrigDenormE ? {1'b0, {`Q_NE-`H_NE{1'b1}}, (`H_NE-1)'(1)} : {XLen3[`H_LEN-2], {`Q_NE-`H_NE{~XLen3[`H_LEN-2]&~XExpZero|XExpMaxE}}, XLen3[`H_LEN-3:`H_NF]}; 
                    YExpE = YOrigDenormE ? {1'b0, {`Q_NE-`H_NE{1'b1}}, (`H_NE-1)'(1)} : {YLen3[`H_LEN-2], {`Q_NE-`H_NE{~YLen3[`H_LEN-2]&~YExpZero|YExpMaxE}}, YLen3[`H_LEN-3:`H_NF]}; 
                    ZExpE = ZOrigDenormE ? {1'b0, {`Q_NE-`H_NE{1'b1}}, (`H_NE-1)'(1)} : {ZLen3[`H_LEN-2], {`Q_NE-`H_NE{~ZLen3[`H_LEN-2]&~ZExpZero|ZExpMaxE}}, ZLen3[`H_LEN-3:`H_NF]}; 

                    // extract the fraction and add the nessesary trailing zeros
                    XFracE = {XLen3[`H_NF-1:0], (`Q_NF-`H_NF)'(0)};
                    YFracE = {YLen3[`H_NF-1:0], (`Q_NF-`H_NF)'(0)};
                    ZFracE = {ZLen3[`H_NF-1:0], (`Q_NF-`H_NF)'(0)};
                end
            endcase
        end

    end

    // is the exponent all 0's
    assign XExpZero = ~XExpNonzero;
    assign YExpZero = ~YExpNonzero;
    assign ZExpZero = ~ZExpNonzero;

    // is the fraction zero
    assign XFracZero = ~|XFracE;
    assign YFracZero = ~|YFracE;
    assign ZFracZero = ~|ZFracE;

    // add the assumed one (or zero if denormal or zero) to create the mantissa
    assign XManE = {XExpNonzero, XFracE};
    assign YManE = {YExpNonzero, YFracE};
    assign ZManE = {ZExpNonzero, ZFracE};

    // is X normalized
    assign XNormE = ~(XExpMaxE|XExpZero);
    
    // is the input a NaN
    //     - force to be a NaN if it isn't properly Nan Boxed
    assign XNaNE = XExpMaxE & ~XFracZero;
    assign YNaNE = YExpMaxE & ~YFracZero;
    assign ZNaNE = ZExpMaxE & ~ZFracZero;

    // is the input a singnaling NaN
    assign XSNaNE = XNaNE&~XFracE[`NF-1];
    assign YSNaNE = YNaNE&~YFracE[`NF-1];
    assign ZSNaNE = ZNaNE&~ZFracE[`NF-1];

    // is the input denormalized
    assign XDenormE = XExpZero & ~XFracZero;
    assign YDenormE = YExpZero & ~YFracZero;
    assign ZDenormE = ZExpZero & ~ZFracZero;

    // is the input infinity
    assign XInfE = XExpMaxE & XFracZero;
    assign YInfE = YExpMaxE & YFracZero;
    assign ZInfE = ZExpMaxE & ZFracZero;

    // is the input zero
    assign XZeroE = XExpZero & XFracZero;
    assign YZeroE = YExpZero & YFracZero;
    assign ZZeroE = ZExpZero & ZFracZero;
    
endmodule
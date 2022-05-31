`include "wally-config.vh"

module unpackinput ( 
    input logic  [`FLEN-1:0]        In,    // inputs from register file
    input logic  [`FPSIZES/3:0]     FmtE,       // format signal 00 - single 01 - double 11 - quad 10 - half
    output logic                    Sgn,    // sign bits of XYZ
    output logic [`NE-1:0]          Exp,    // exponents of XYZ (converted to largest supported precision)
    output logic [`NF:0]            Man,    // mantissas of XYZ (converted to largest supported precision)
    output logic                    NaN,    // is XYZ a NaN
    output logic                    SNaN, // is XYZ a signaling NaN
    output logic                    Denorm,   // is XYZ denormalized
    output logic                    Zero,         // is XYZ zero
    output logic                    Inf,            // is XYZ infinity
    output logic                    ExpMax                       // does In have the maximum exponent (NaN or Inf)
);
 
    logic [`NF-1:0] Frac; //Fraction of XYZ
    logic           ExpNonZero; // is the exponent of XYZ non-zero
    logic           FracZero; // is the fraction zero
    logic           ExpZero;
    
    if (`FPSIZES == 1) begin        // if there is only one floating point format supported
        assign Sgn = In[`FLEN-1];  // sign bit
        assign Frac = In[`NF-1:0];  // fraction (no assumed 1)
        assign FracZero = ~|Frac; // is the fraction zero?
        assign ExpNonZero = |Exp;  // is the exponent non-zero
        assign Denorm = ~ExpNonZero & ~FracZero; // is the input (in its original format) denormalized
        assign Exp = {In[`FLEN-2:`NF+1], In[`NF]|Denorm};  // exponent.  Denormalized numbers have effective biased exponent of 1
        assign ExpMax = &Exp;  // is the exponent all 1's
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

        logic  [`LEN1-1:0]  Len1; // Remove NaN boxing or NaN, if not properly NaN boxed

        // Check NaN boxing, If the value is not properly NaN boxed, set the value to a quiet NaN
        assign Len1 = &In[`FLEN-1:`LEN1] ? In[`LEN1-1:0] : {1'b0, {`NE1+1{1'b1}}, (`NF1-1)'(0)};

        // choose sign bit depending on format - 1=larger precsion 0=smaller precision
        assign Sgn = FmtE ? In[`FLEN-1] : Len1[`LEN1-1];

        // extract the fraction, add trailing zeroes to the mantissa if nessisary
        assign Frac = FmtE ? In[`NF-1:0] : {Len1[`NF1-1:0], (`NF-`NF1)'(0)};

        // is the fraction zero
        assign FracZero = ~|Frac;
        
        // is the exponent non-zero
        assign ExpNonZero = FmtE ? |In[`FLEN-2:`NF] : |Len1[`LEN1-2:`NF1]; 

        // is the input (in it's original format) denormalized
        assign Denorm = ~ExpNonZero & ~FracZero;

        // example double to single conversion:
        // 1023 = 0011 1111 1111
        // 127  = 0000 0111 1111 (subtract this)
        // 896  = 0011 1000 0000
        // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
        // dexp = 0bdd dbbb bbbb 
        // also need to take into account possible zero/denorm/inf/NaN values

        // extract the exponent, converting the smaller exponent into the larger precision if nessisary
        //      - if the original precision had a denormal number convert the exponent value 1
        assign Exp = FmtE ? {In[`FLEN-2:`NF+1], In[`NF]|Denorm} : {Len1[`LEN1-2], {`NE-`NE1{~Len1[`LEN1-2]}}, Len1[`LEN1-3:`NF1+1], Len1[`NF1]|Denorm}; 
 


        // is the exponent all 1's
        assign ExpMax = FmtE ? &In[`FLEN-2:`NF] : &Len1[`LEN1-2:`NF1];
    

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

        logic  [`LEN1-1:0]  Len1; // Remove NaN boxing or NaN, if not properly NaN boxed for larger percision
        logic  [`LEN2-1:0]  Len2; // Remove NaN boxing or NaN, if not properly NaN boxed for smallest precision
        
        // Check NaN boxing, If the value is not properly NaN boxed, set the value to a quiet NaN - for larger precision
        assign Len1 = &In[`FLEN-1:`LEN1] ? In[`LEN1-1:0] : {1'b0, {`NE1+1{1'b1}}, (`NF1-1)'(0)};

        // Check NaN boxing, If the value is not properly NaN boxed, set the value to a quiet NaN - for smaller precision
        assign Len2 = &In[`FLEN-1:`LEN2] ? In[`LEN2-1:0] : {1'b0, {`NE2+1{1'b1}}, (`NF2-1)'(0)};


        // extract the sign bit
        always_comb
            case (FmtE)
                `FMT:  Sgn = In[`FLEN-1];
                `FMT1: Sgn = Len1[`LEN1-1];
                `FMT2: Sgn = Len2[`LEN2-1];
                default: Sgn = 0;
            endcase

        // extract the fraction
        always_comb
            case (FmtE)
                `FMT: Frac = In[`NF-1:0];
                `FMT1: Frac = {Len1[`NF1-1:0], (`NF-`NF1)'(0)};
                `FMT2: Frac = {Len2[`NF2-1:0], (`NF-`NF2)'(0)};
                default: Frac = 0;
            endcase

        // is the fraction zero
        assign FracZero = ~|Frac;


        // is the exponent non-zero
        always_comb
            case (FmtE)
                `FMT:  ExpNonZero = |In[`FLEN-2:`NF];     // if input is largest precision (`FLEN - ie quad or double)
                `FMT1: ExpNonZero = |Len1[`LEN1-2:`NF1];  // if input is larger precsion (`LEN1 - double or single)
                `FMT2: ExpNonZero = |Len2[`LEN2-2:`NF2]; // if input is smallest precsion (`LEN2 - single or half)
                default: ExpNonZero = 0; 
            endcase
            
        // is the input (in it's original format) denormalized
        assign Denorm = ~ExpNonZero & ~FracZero;

        // example double to single conversion:
        // 1023 = 0011 1111 1111
        // 127  = 0000 0111 1111 (subtract this)
        // 896  = 0011 1000 0000
        // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
        // dexp = 0bdd dbbb bbbb 
        // also need to take into account possible zero/denorm/inf/NaN values

        // convert the larger precision's exponent to use the largest precision's bias
        always_comb 
            case (FmtE)
                `FMT:  Exp = {In[`FLEN-2:`NF+1], In[`NF]|Denorm};
                `FMT1: Exp = {Len1[`LEN1-2], {`NE-`NE1{~Len1[`LEN1-2]}}, Len1[`LEN1-3:`NF1+1], Len1[`NF1]|Denorm}; 
                `FMT2: Exp = {Len2[`LEN2-2], {`NE-`NE2{~Len2[`LEN2-2]}}, Len2[`LEN2-3:`NF2+1], Len2[`NF2]|Denorm}; 
                default: Exp = 0;
            endcase

        // is the exponent all 1's
        always_comb
            case (FmtE)
                `FMT:  ExpMax = &In[`FLEN-2:`NF];
                `FMT1: ExpMax = &Len1[`LEN1-2:`NF1];
                `FMT2: ExpMax = &Len2[`LEN2-2:`NF2];
                default: ExpMax = 0;
            endcase

    end else if (`FPSIZES == 4) begin      // if all precsisons are supported - quad, double, single, and half
    
        //    quad   |  double  |  single  |  half    
        //-------------------------------------------------------------------
        //   `Q_LEN  |  `D_LEN  |  `S_LEN  |  `H_LEN     length of floating point number
        //   `Q_NE   |  `D_NE   |  `S_NE   |  `H_NE      length of exponent
        //   `Q_NF   |  `D_NF   |  `S_NF   |  `H_NF      length of fraction
        //   `Q_BIAS |  `D_BIAS |  `S_BIAS |  `H_BIAS    exponent's bias value
        //   `Q_FMT  |  `D_FMT  |  `S_FMT  |  `H_FMT     precision's format value - Q=11 D=01 S=00 H=10


        logic  [`D_LEN-1:0]  Len1; // Remove NaN boxing or NaN, if not properly NaN boxed for double percision
        logic  [`S_LEN-1:0]  Len2; // Remove NaN boxing or NaN, if not properly NaN boxed for single percision
        logic  [`H_LEN-1:0]  Len3; // Remove NaN boxing or NaN, if not properly NaN boxed for half percision
        
        // Check NaN boxing, If the value is not properly NaN boxed, set the value to a quiet NaN - for double precision
        assign Len1 = &In[`Q_LEN-1:`D_LEN] ? In[`D_LEN-1:0] : {1'b0, {`D_NE+1{1'b1}}, (`D_NF-1)'(0)};

        // Check NaN boxing, If the value is not properly NaN boxed, set the value to a quiet NaN - for single precision
        assign Len2 = &In[`Q_LEN-1:`S_LEN] ? In[`S_LEN-1:0] : {1'b0, {`S_NE+1{1'b1}}, (`S_NF-1)'(0)};

        // Check NaN boxing, If the value is not properly NaN boxed, set the value to a quiet NaN - for half precision
        assign Len3 = &In[`Q_LEN-1:`H_LEN] ? In[`H_LEN-1:0] : {1'b0, {`H_NE+1{1'b1}}, (`H_NF-1)'(0)};

        // extract sign bit
        always_comb
            case (FmtE)
                2'b11: Sgn = In[`Q_LEN-1];
                2'b01: Sgn = Len1[`D_LEN-1];
                2'b00: Sgn = Len2[`S_LEN-1];
                2'b10: Sgn = Len3[`H_LEN-1];
            endcase
            

        // extract the fraction
        always_comb
            case (FmtE)
                2'b11: Frac = In[`Q_NF-1:0];
                2'b01: Frac = {Len1[`D_NF-1:0], (`Q_NF-`D_NF)'(0)};
                2'b00: Frac = {Len2[`S_NF-1:0], (`Q_NF-`S_NF)'(0)};
                2'b10: Frac = {Len3[`H_NF-1:0], (`Q_NF-`H_NF)'(0)};
            endcase

        // is the fraction zero
        assign FracZero = ~|Frac;

        // is the exponent non-zero
        always_comb
            case (FmtE)
                2'b11: ExpNonZero = |In[`Q_LEN-2:`Q_NF];
                2'b01: ExpNonZero = |Len1[`D_LEN-2:`D_NF];
                2'b00: ExpNonZero = |Len2[`S_LEN-2:`S_NF]; 
                2'b10: ExpNonZero = |Len3[`H_LEN-2:`H_NF]; 
            endcase

        // is the input (in it's original format) denormalized
        assign Denorm = ~ExpNonZero & ~FracZero;


        // example double to single conversion:
        // 1023 = 0011 1111 1111
        // 127  = 0000 0111 1111 (subtract this)
        // 896  = 0011 1000 0000
        // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
        // dexp = 0bdd dbbb bbbb 
        // also need to take into account possible zero/denorm/inf/NaN values
        
        // convert the double precsion exponent into quad precsion
        always_comb
            case (FmtE)
                2'b11: Exp = {In[`Q_LEN-2:`Q_NF+1], In[`Q_NF]|Denorm};
                2'b01: Exp = {Len1[`D_LEN-2], {`Q_NE-`D_NE{~Len1[`D_LEN-2]}}, Len1[`D_LEN-3:`D_NF+1], Len1[`D_NF]|Denorm};
                2'b00: Exp = {Len2[`S_LEN-2], {`Q_NE-`S_NE{~Len2[`S_LEN-2]}}, Len2[`S_LEN-3:`S_NF+1], Len2[`S_NF]|Denorm};
                2'b10: Exp = {Len3[`H_LEN-2], {`Q_NE-`H_NE{~Len3[`H_LEN-2]}}, Len3[`H_LEN-3:`H_NF+1], Len3[`H_NF]|Denorm}; 
            endcase


        // is the exponent all 1's
        always_comb 
            case (FmtE)
                2'b11: ExpMax = &In[`Q_LEN-2:`Q_NF];
                2'b01: ExpMax = &Len1[`D_LEN-2:`D_NF];
                2'b00: ExpMax = &Len2[`S_LEN-2:`S_NF];
                2'b10: ExpMax = &Len3[`H_LEN-2:`H_NF];
            endcase

    end

    // is the exponent all 0's
    assign ExpZero = ~ExpNonZero;

    // add the assumed one (or zero if denormal or zero) to create the mantissa
    assign Man = {ExpNonZero, Frac};
    
    // is the input a NaN
    //     - force to be a NaN if it isn't properly Nan Boxed
    assign NaN = ExpMax & ~FracZero;

    // is the input a singnaling NaN
    assign SNaN = NaN&~Frac[`NF-1];

    // is the input infinity
    assign Inf = ExpMax & FracZero;

    // is the input zero
    assign Zero = ExpZero & FracZero;
    
endmodule
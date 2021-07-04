///////////////////////////////////////////
// csrn.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//          dottolia@hmc.edu 3 May 2021 - fix bug with utvec getting wrong value
//
// Purpose: User-Mode Control and Status Registers for User Mode Exceptions
//          See RISC-V Privileged Mode Specification 20190608 Table 2.2
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module csrn #(parameter 
  USTATUS     =12'h000,
  UIE = 12'h004,
  UTVEC = 12'h005,
  USCRATCH = 12'h040,
  UEPC = 12'h041,
  UCAUSE = 12'h042,
  UTVAL = 12'h043,
  UIP = 12'h044) (
    input  logic             clk, reset, 
    input  logic             StallW,
    input  logic             CSRNWriteM, UTrapM,
    input  logic [11:0]      CSRAdrM,
    input  logic [`XLEN-1:0] NextEPCM, NextCauseM, NextMtvalM, USTATUS_REGW, 
    input  logic [`XLEN-1:0] CSRWriteValM,
    output logic [`XLEN-1:0] CSRNReadValM, UEPC_REGW, UTVEC_REGW, 
    input  logic [11:0]      UIP_REGW, UIE_REGW, 
    output logic             WriteUSTATUSM,
    output logic             IllegalCSRNAccessM
  );

  // User mode CSRs below only needed when user mode traps are supported
  generate
    if (`N_SUPPORTED) begin
      logic WriteUTVECM;
      logic WriteUSCRATCHM, WriteUEPCM;
      logic WriteUCAUSEM, WriteUTVALM;
      logic [`XLEN-1:0] UEDELEG_REGW, UIDELEG_REGW;
      logic [`XLEN-1:0] USCRATCH_REGW, UCAUSE_REGW, UTVAL_REGW;
      
      // Write enables
      assign WriteUSTATUSM = CSRNWriteM && (CSRAdrM == USTATUS) && ~StallW;
      assign WriteUTVECM = CSRNWriteM && (CSRAdrM == UTVEC) && ~StallW;
      assign WriteUEPCM = UTrapM | (CSRNWriteM && (CSRAdrM == UEPC)) && ~StallW;
      assign WriteUCAUSEM = UTrapM | (CSRNWriteM && (CSRAdrM == UCAUSE)) && ~StallW;
      assign WriteUTVALM = UTrapM | (CSRNWriteM && (CSRAdrM == UTVAL)) && ~StallW;

      // CSRs
      flopenl #(`XLEN) UTVECreg(clk, reset, WriteUTVECM, {CSRWriteValM[`XLEN-1:2], 1'b0, CSRWriteValM[0]}, `RESET_VECTOR, UTVEC_REGW);
      flopenr #(`XLEN) USCRATCHreg(clk, reset, WriteUSCRATCHM, CSRWriteValM, USCRATCH_REGW);
      flopenr #(`XLEN) UEPCreg(clk, reset, WriteUEPCM, NextEPCM, UEPC_REGW); 
      flopenr #(`XLEN) UCAUSEreg(clk, reset, WriteUCAUSEM, NextCauseM, UCAUSE_REGW); 
      flopenr #(`XLEN) UTVALreg(clk, reset, WriteUTVALM, NextMtvalM, UTVAL_REGW);

      // CSR Reads
      always_comb begin
        IllegalCSRNAccessM = 0;
        case (CSRAdrM) 
          USTATUS:   CSRNReadValM = USTATUS_REGW;
          UTVEC:     CSRNReadValM = UTVEC_REGW;
          UIP:       CSRNReadValM = {{(`XLEN-12){1'b0}}, UIP_REGW};
          UIE:       CSRNReadValM = {{(`XLEN-12){1'b0}}, UIE_REGW};
          USCRATCH:  CSRNReadValM = USCRATCH_REGW;
          UEPC:      CSRNReadValM = UEPC_REGW;
          UCAUSE:    CSRNReadValM = UCAUSE_REGW;
          UTVAL:     CSRNReadValM = UTVAL_REGW;
          default: begin
                     CSRNReadValM = 0; 
                     IllegalCSRNAccessM = 1;
          end         
        endcase
      end
    end else begin // if not supported
      assign WriteUSTATUSM = 0;
      assign CSRNReadValM = 0;
      assign UEPC_REGW = 0;
      assign UTVEC_REGW = 0;
      assign IllegalCSRNAccessM = 1;
    end
  endgenerate
endmodule

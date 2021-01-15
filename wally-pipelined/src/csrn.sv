///////////////////////////////////////////
// csrn.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
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

`include "wally-macros.sv"

module csrn #(parameter XLEN=64, MISA=0,
  USTATUS     =12'h000,
  UIE = 12'h004,
  UTVEC = 12'h005,
  USCRATCH = 12'h040,
  UEPC = 12'h041,
  UCAUSE = 12'h042,
  UTVAL = 12'h043,
  UIP = 12'h044) (
    input  logic clk, reset, 
    input  logic CSRUWriteM, UTrapM,
    input  logic [11:0] CSRAdrM,
    input  logic [XLEN-1:0] resetExceptionVector,
    input  logic [XLEN-1:0] NextEPCM, NextCauseM, NextMtvalM, USTATUS_REGW, 
    input  logic [XLEN-1:0] CSRWriteValM,
    output logic [XLEN-1:0] CSRUReadValM, UEPC_REGW, UTVEC_REGW, 
    input  logic [11:0]     UIP_REGW, UIE_REGW, 
    output logic            WriteUIPM, WriteUIEM,
    output logic            WriteUSTATUSM,
    output logic            IllegalCSRUAccessM
  );

  logic [XLEN-1:0] zero = 0;

  // *** add floating point CSRs here.  Maybe move stuff below to csrn to support reading

  // User mode CSRs below only needed when user mode traps are supported
  generate  
    if (`N_SUPPORTED) begin
      logic WriteUTVECM;
      logic WriteUSCRATCHM, WriteUEPCM;
      logic WriteUCAUSEM, WriteUTVALM;
      logic [XLEN-1:0] UEDELEG_REGW, UIDELEG_REGW, UIP_REGW, UIE_REGW;
      logic [XLEN-1:0] USCRATCH_REGW, UCAUSE_REGW, UTVAL_REGW;
      
      // Write enables
      assign WriteUSTATUSM = CSRUWriteM && (CSRAdrM == USTATUS);
      assign WriteUTVECM = CSRUWriteM && (CSRAdrM == UTVEC);
      assign WriteUIPM = CSRUWriteM && (CSRAdrM == UIP);
      assign WriteUIEM = CSRUWriteM && (CSRAdrM == UIE);
      assign WriteUEPCM = UTrapM | (CSRUWriteM && (CSRAdrM == UEPC));
      assign WriteUCAUSEM = UTrapM | (CSRUWriteM && (CSRAdrM == UCAUSE));
      assign WriteUTVALM = UTrapM | (CSRUWriteM && (CSRAdrM == UTVAL));

      // CSRs
      flopenl #(XLEN) UTVECreg(clk, reset, WriteUTVECM, CSRWriteValM, resetExceptionVector, UTVEC_REGW);
      // flopenl #(XLEN) UIPreg(clk, reset, WriteUIPM, CSRWriteValM, zero, UIP_REGW);
      // flopenl #(XLEN) UIEreg(clk, reset, WriteUIEM, CSRWriteValM, zero, UIE_REGW);
      flopenr #(XLEN) USCRATCHreg(clk, reset, WriteUSCRATCHM, CSRWriteValM, USCRATCH_REGW);
      flopenr #(XLEN) UEPCreg(clk, reset, WriteUEPCM, NextEPCM, UEPC_REGW); 
      flopenr #(XLEN) UCAUSEreg(clk, reset, WriteUCAUSEM, NextCauseM, UCAUSE_REGW); 
      flopenr #(XLEN) UTVALreg(clk, reset, WriteUTVALM, NextMtvalM, UTVAL_REGW);

      // CSR Reads
      always_comb begin
        IllegalCSRUAccessM = 0;
        case (CSRAdrM) 
          USTATUS:   CSRUReadValM = USTATUS_REGW;
          UTVEC:     CSRUReadValM = UTVEC_REGW;
          UIP:       CSRUReadValM = {{(XLEN-12){1'b0}}, UIP_REGW};
          UIE:       CSRUReadValM = {{(XLEN-12){1'b0}}, UIE_REGW};
          USCRATCH:  CSRUReadValM = USCRATCH_REGW;
          UEPC:      CSRUReadValM = UEPC_REGW;
          UCAUSE:    CSRUReadValM = UCAUSE_REGW;
          UTVAL:     CSRUReadValM = UTVAL_REGW;
          default: begin
                     CSRUReadValM = 0; 
                     IllegalCSRUAccessM = 1;
          end         
        endcase
      end
    end else begin // if not supported
      assign WriteUSTATUSM = 0;
      assign CSRUReadValM = 0;
      assign UEPC_REGW = 0;
      assign UTVEC_REGW = 0;
      assign IllegalCSRUAccessM = 1;
    end
  endgenerate
endmodule
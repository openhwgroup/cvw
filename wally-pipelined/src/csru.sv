///////////////////////////////////////////
// csru.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: User-Mode Control and Status Registers for Floating Point

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

module csru #(parameter 
  FFLAGS = 12'h001,
  FRM = 12'h002,
  FCSR = 12'h003) (
    input  logic clk, reset, 
    input  logic CSRUWriteM,
    input  logic [11:0] CSRAdrM,
    input  logic [`XLEN-1:0] CSRWriteValM,
    output logic [`XLEN-1:0] CSRUReadValM,  
    input  logic [4:0]      SetFflagsM,
    output logic [2:0]      FRM_REGW,
    output logic            IllegalCSRUAccessM
  );

  // Floating Point CSRs in User Mode only needed if Floating Point is supported
  generate  
    if (`F_SUPPORTED) begin
      logic [4:0] FFLAGS_REGW;
      logic WriteFFLAGSM, WriteFRMM, WriteFCSRM;
      logic [2:0] NextFRMM;
      logic [4:0] NextFFLAGSM;
        
      // Write enables
      assign WriteFCSRM = CSRUWriteM && (CSRAdrM == FCSR);
      assign WriteFFLAGSM = CSRUWriteM && (CSRAdrM == FFLAGS) | WriteFCSRM ;
      assign WriteFRMM = CSRUWriteM && (CSRAdrM == FRM) | WriteFCSRM;
    
      // Write Values
      assign NextFRMM = WriteFCSRM ? CSRWriteValM[7:5] : CSRWriteValM[2:0];
      assign NextFFLAGSM = WriteFFLAGSM ? CSRWriteValM[4:0] : FFLAGS_REGW | SetFflagsM;

      // CSRs
      flopenr #(3) FRMreg(clk, reset, WriteFRMM, NextFRMM, FRM_REGW);
      flopr   #(5) FFLAGSreg(clk, reset, NextFFLAGSM, FFLAGS_REGW); 

      // CSR Reads
      always_comb begin
        IllegalCSRUAccessM = 0;
        case (CSRAdrM) 
          FFLAGS:    CSRUReadValM = {{(`XLEN-5){1'b0}}, FFLAGS_REGW};
          FRM:       CSRUReadValM = {{(`XLEN-3){1'b0}}, FRM_REGW};
          FCSR:      CSRUReadValM = {{(`XLEN-8){1'b0}}, FRM_REGW, FFLAGS_REGW};
          default: begin
                     CSRUReadValM = 0; 
                     IllegalCSRUAccessM = 1;
          end         
        endcase
      end
    end else begin // if not supported
      assign FRM_REGW = 0;
      assign CSRUReadValM = 0;
      assign IllegalCSRUAccessM = 1;
    end
  endgenerate
endmodule
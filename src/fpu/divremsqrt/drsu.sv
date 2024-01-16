///////////////////////////////////////////
// drsu.sv
//
// Written: kekim@hmc.edu
// Modified:19 May 2023
//
// Purpose: Combined Divide and Square Root Floating Point and Integer Unit with postprocessing
// 
// Documentation: RISC-V System on Chip Design Chapter 13
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////


module drsu import cvw::*;  #(parameter cvw_t P) (
  input  logic                clk, 
  input  logic                reset, 
  input  logic [P.FMTBITS-1:0] FmtE,
  input  logic                XsE, YsE,
  input  logic [P.NF:0]        XmE, YmE,
  input  logic [P.NE-1:0]      XeE, YeE,
  input  logic                XInfE, YInfE, 
  input  logic                XZeroE, YZeroE, 
  input  logic                XNaNE, YNaNE, 
  input  logic                XSNaNE, YSNaNE,
  input  logic                FDivStartE, IDivStartE,
  input  logic                StallM,
  input  logic                FlushE,
  input  logic                SqrtE, SqrtM,
  input  logic [P.XLEN-1:0]    ForwardedSrcAE, ForwardedSrcBE, // these are the src outputs before the mux choosing between them and PCE to put in srcA/B
  input  logic [2:0]          Funct3E, Funct3M,
  input  logic                IntDivE, W64E,
  input  logic [2:0]          Frm,
  input  logic [2:0]          OpCtrl,
  input  logic [1:0]          PostProcSel,
  output logic                FDivBusyE, IFDivStartE, FDivDoneE,
  output logic [P.FLEN-1:0]    FResM,
  output logic [P.XLEN-1:0]    FIntDivResultM,
  output logic [4:0]          FlgM
);

  // Floating-point division and square root module, with optional integer division and remainder
  // Computes X/Y, sqrt(X), A/B, or A%B

  logic [P.DIVb+3:0]           WS, WC;                       // Partial remainder components
  logic [P.DIVb+3:0]           X;                            // Iterator Initial Value (from dividend)
  logic [P.DIVb+3:0]           D;                            // Iterator Divisor
  logic [P.DIVb:0]             FirstU, FirstUM;              // Intermediate result values
  logic [P.DIVb+1:0]           FirstC;                       // Step tracker
  logic                       Firstun;                      // Quotient selection
  logic                       WZeroE;                       // Early termination flag
  logic [P.DURLEN-1:0]         CyclesE;                      // FSM cycles
  logic                       SpecialCaseM;                 // Divide by zero, square root of negative, etc.
  logic                       DivStartE;                    // Enable signal for flops during stall
                                                            
  // Integer div/rem signals                                
  logic                       BZeroM;                       // Denominator is zero
  logic                       IntDivM;                      // Integer operation
  logic [P.DIVBLEN:0]          nM, mM;                       // Shift amounts
  logic                       NegQuotM, ALTBM, AsM, W64M;   // Special handling for postprocessor
  logic [P.XLEN-1:0]           AM;                           // Original Numerator for postprocessor
  logic                       ISpecialCaseE;                // Integer div/remainder special cases
  logic [P.DIVb:0]             UmM;
  logic [P.NE+1:0]             UeM;
  logic                       DivStickyM;

  divremsqrt #(P) divremsqrt(.clk, .reset, .XsE, .FmtE, .XmE, .YmE, 
            .XeE, .YeE, .SqrtE, .SqrtM,
                    .XInfE, .YInfE, .XZeroE, .YZeroE, 
            .XNaNE, .YNaNE, 
                    .FDivStartE, .IDivStartE, .W64E,
                    .StallM, .DivStickyM, .FDivBusyE, .UeM,
                    .UmM,
                    .FlushE, .ForwardedSrcAE, .ForwardedSrcBE, .Funct3M,
                    .Funct3E, .IntDivE, .FIntDivResultM,
                    .FDivDoneE, .IFDivStartE);
  divremsqrtpostprocess #(P) divremsqrtpostprocess(.Xs(XsE), .Ys(YsE), .Xm(XmE), .Ym(YmE), .Frm(Frm), .Fmt(FmtE), .OpCtrl,
    .XZero(XZeroE), .YZero(YZeroE), .XInf(XInfE), .YInf(YInfE), .XNaN(XNaNE), .YNaN(YNaNE), .XSNaN(XSNaNE), 
    .YSNaN(YSNaNE), .PostProcSel,.DivSticky(DivStickyM), .DivUe(UeM), .DivUm(UmM), .PostProcRes(FResM), .PostProcFlg(FlgM));
endmodule


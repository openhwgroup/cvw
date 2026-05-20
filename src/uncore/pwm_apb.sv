///////////////////////////////////////////
// pwm_apb.sv
//
// Written: naichewa@gmail.com 4/29/2026
// Modified:
//
// Purpose: PWM module
//  https://docs.google.com/document/d/1erHBVchBtwmgZ0bCNjb88spYfN7CpRbhmSNFH6cO8CY/edit?tab=t.0
//
// Documentation: RISC-V System on Chip Design
// Based on PWM design from SiFive 5U540-C000 manual version 1.0
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
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

/* Issues:
parameterize
apb access/ adrdec size mask
plic_num_srcs
all config.vhs range, base
find any other changes needed to connect module to uncore/core(ex:
currently changed plic, uncore.cv, soc.sv, need address protector change)
plic source number
ZeroCompare all comparators???
*/
module pwm_apb import cvw::*; #(parameter cvw_t P) (
  input  logic                PCLK, PRESETn,
  input  logic                PSEL,
  input  logic [7:0]          PADDR,
  input  logic [P.XLEN-1:0]   PWDATA,
  input  logic [P.XLEN/8-1:0] PSTRB,
  input  logic                PWRITE,
  input  logic                PENABLE,
  output logic [P.XLEN-1:0]   PRDATA,
  output logic                PREADY,
  output logic                PWMIntr,
  output logic [3:0]          PWMGPIO
);

  // register map
  localparam PWM_CFG        = 8'h00;
  localparam PWM_COUNT      = 8'h08;
  localparam PWM_S          = 8'h10;
  localparam PWM_CMP0       = 8'h20;
  localparam PWM_CMP1       = 8'h24;
  localparam PWM_CMP2       = 8'h28;
  localparam PWM_CMP3       = 8'h2C;

  // PWM control registers
  logic [20:0] PWMConfig;
  logic [30:0] PWMCount;
  logic [15:0] PWMScaled;
  logic [15:0] PWMCompare0;
  logic [15:0] PWMCompare1;
  logic [15:0] PWMCompare2;
  logic [15:0] PWMCompare3;

    // PWMConfig signals
  logic [3:0] PWMScale;
  logic PWMSticky, PWMZeroCompare, PWMDeglitch;
  logic PWMEnAlways, PWMEnOneShot;
  logic [3:0] PWMCompareCenter;
  logic [3:0] PWMCompareGang;
  logic [3:0] PWMCompareIP;

  // PWMCount signals
  logic Carryout;
  logic PWMCountEn;
  logic PWMOneShotEnReset;
  logic [30:0] PWMCountPrescaled;
  logic [30:0] PWMCountIncrement;

  // Register signal logic

  assign PWMScale = PWMConfig[3:0];
  assign PWMSticky = PWMConfig[4];
  assign PWMZeroCompare = PWMConfig[5];
  assign PWMDeglitch = PWMConfig[6];
  assign PWMEnAlways = PWMConfig[7];
  assign PWMEnOneShot = PWMConfig[8];
  assign PWMCompareCenter = PWMConfig[12:9];
  assign PWMCompareGang = PWMConfig[16:13];

  assign Carryout = &PWMScaled;
  assign PWMCountEn = PWMEnAlways | PWMEnOneShot;
  assign PWMCountPrescaled = PWMCount >> PWMScale;
  assign PWMCountIncrement = PWMCount + 1;

  // Combinatorial signal logic
  logic [3:0] PWMCompareBoolean;
  logic [3:0] PWMDeglitchMux;
  logic PWMCountReset;
  logic [3:0] PWMCompareXNOR;


  assign PWMOneShotEnReset = (PWMCompareBoolean[0] & PWMZeroCompare) | Carryout;
  assign PWMCountReset = PWMOneShotEnReset | (~PRESETn);

  // Deglitch circuit signals
  logic PWMHoldIn;
  logic PWMHoldOut;
  logic [3:0] PWMCompareIPIn;

  assign PWMHoldIn = (~PWMOneShotEnReset & PWMDeglitch) | PWMSticky;

  // Bus interface signals
  logic [7:0]  Entry;
  logic        Memwrite;
  logic [31:0] Din,  Dout;

  assign Entry = {PADDR[7:2],2'b00};  //  32-bit word-aligned accesses
  assign Memwrite = PWRITE & PENABLE & PSEL;  // Only write in access phase
  assign PREADY = 1'b1;
// Account for subword read/write circuitry


  assign Din = PWDATA[31:0];
  if (P.XLEN == 64) assign PRDATA = {Dout,  Dout};
  else              assign PRDATA =  Dout;

  // Register access
  always_ff@(posedge PCLK)
    if (~PRESETn) begin
      PWMConfig[20:0] <= 21'b0;
      PWMCompare0 <= 16'hFFFF;
      PWMCompare1 <= 16'hFFFF;
      PWMCompare2 <= 16'hFFFF;
      PWMCompare3 <= 16'hFFFF;
    end else if (PWMOneShotEnReset) PWMConfig[8] <= 1'b0;
    else begin // writes
      /* verilator lint_off CASEINCOMPLETE */
      if (Memwrite)
        case(Entry) // flop to sample inputs
          PWM_CFG:   PWMConfig <= {Din[31:24], Din[19:16], Din[13:12], Din[10:8], Din[3:0]};
          //PWM_COUNT: PWMCount <= Din[30:0];
          //PWM_S:     PWMScaled <= Din[15:0];
          PWM_CMP0:  PWMCompare0 <= Din[15:0];
          PWM_CMP1:  PWMCompare1 <= Din[15:0];
          PWM_CMP2:  PWMCompare2 <= Din[15:0];
          PWM_CMP3:  PWMCompare3 <= Din[15:0];
        endcase
      /* verilator lint_on CASEINCOMPLETE */



      case(Entry) // Flop to sample inputs
        PWM_CFG:   Dout <= {PWMConfig[20:13], 4'b0, PWMConfig[12:9], 2'b0, PWMConfig[8:7], 1'b0, PWMConfig[6:4], 4'b0, PWMConfig[3:0]};
        PWM_COUNT: Dout <= {1'b0, PWMCount};
        PWM_S:     Dout <= {16'b0, PWMScaled[15:0]};
        PWM_CMP0:  Dout <= {16'b0, PWMCompare0[15:0]};
        PWM_CMP1:  Dout <= {16'b0, PWMCompare1[15:0]};
        PWM_CMP2:  Dout <= {16'b0, PWMCompare2[15:0]};
        PWM_CMP3:  Dout <= {16'b0, PWMCompare3[15:0]};
        default:   Dout <= 32'b0;
      endcase
    end


  // PWMCount register
  /*
  always_ff @(posedge PCLK)
    if (PWMOneShotEnReset | ~PRESETn) PWMCount <= 31'b0;
    else if (PWMCountEn) PWMCount <= PWMCount + 1;
  */
  flopenr #(31) pwmcountreg(PCLK, PWMCountReset, PWMCountEn,
                            PWMCountIncrement, PWMCount);

  // PWMScaled register
  flop #(16) pwmscaledreg(PCLK,
                          PWMCountPrescaled[15:0], PWMScaled);


  flop #(1) pwmholdreg(PCLK,
                       PWMHoldIn, PWMHoldOut);
  //parameterizable pwm comparators
  assign PWMDeglitchMux[0] = PWMScaled[15] | PWMCompareCenter[0];
  assign PWMCompareXNOR[0] = ({16{PWMDeglitchMux[0]}} ~^ PWMScaled);
  assign PWMCompareBoolean[0] = PWMCompareXNOR[0] >= PWMCompare0;
  assign PWMCompareIPIn[0] = PWMDeglitchMux[0] ? PWMCompareBoolean[0] : (PWMCompareBoolean[0] | (PWMHoldOut & PWMCompareIP[0]));

  flop #(1) pwmcompareipreg0(PCLK,
                            PWMCompareIPIn[0], PWMCompareIP[0]);

  assign PWMGPIO[0] = PWMCompareIP[0] & (PWMCompareGang[0] ~& PWMCompareIP[1]);


  assign PWMDeglitchMux[1] = PWMScaled[15] | PWMCompareCenter[1];
  assign PWMCompareXNOR[1] = ({16{PWMDeglitchMux[1]}} ~^ PWMScaled);
  assign PWMCompareBoolean[1] = PWMCompareXNOR[1] >= PWMCompare1;
  assign PWMCompareIPIn[1] = PWMDeglitchMux[1] ? PWMCompareBoolean[1] : (PWMCompareBoolean[1] | (PWMHoldOut & PWMCompareIP[1]));

  flop #(1) pwmcompareipreg1(PCLK,
                            PWMCompareIPIn[1], PWMCompareIP[1]);

  assign PWMGPIO[1] = PWMCompareIP[1] & (PWMCompareGang[1] ~& PWMCompareIP[2]);


  assign PWMDeglitchMux[2] = PWMScaled[15] | PWMCompareCenter[2];
  assign PWMCompareXNOR[2] = ({16{PWMDeglitchMux[2]}} ~^ PWMScaled);
  assign PWMCompareBoolean[2] = PWMCompareXNOR[2] >= PWMCompare2;
  assign PWMCompareIPIn[2] = PWMDeglitchMux[2] ? PWMCompareBoolean[2] : (PWMCompareBoolean[2] | (PWMHoldOut & PWMCompareIP[2]));

  flop #(1) pwmcompareipreg2(PCLK,
                            PWMCompareIPIn[2], PWMCompareIP[2]);

  assign PWMGPIO[2] = PWMCompareIP[2] & (PWMCompareGang[2] ~& PWMCompareIP[3]);


  assign PWMDeglitchMux[3] = PWMScaled[15] | PWMCompareCenter[3];
  assign PWMCompareXNOR[3] = ({16{PWMDeglitchMux[3]}} ~^ PWMScaled);
  assign PWMCompareBoolean[3] = PWMCompareXNOR[3] >= PWMCompare3;
  assign PWMCompareIPIn[3] = PWMDeglitchMux[3] ? PWMCompareBoolean[3] : (PWMCompareBoolean[3] | (PWMHoldOut & PWMCompareIP[3]));

  flop #(1) pwmcompareipreg3(PCLK,
                            PWMCompareIPIn[3], PWMCompareIP[3]);

  assign PWMGPIO[3] = PWMCompareIP[3] & (PWMCompareGang[3] ~& PWMCompareIP[0]);


  assign PWMIntr = |(PWMCompareIP);

endmodule

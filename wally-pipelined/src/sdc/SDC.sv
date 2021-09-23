///////////////////////////////////////////
// SDC.sv
//
// Written: Ross Thompson September 22, 2021
// Modified: 
//
// Purpose: SDC interface to AHBLite BUS.
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

`define SDCCLKDIV 2

module SDC 
  (input  logic             HCLK, 
   input logic 		    HRESETn,
   input logic 		    HSELSDC,
   input logic [4:0] 	    HADDR,
   input logic 		    HWRITE,
   input logic 		    HREADY,
   input logic [1:0] 	    HTRANS,
   input logic [`XLEN-1:0]  HWDATA,
   output logic [`XLEN-1:0] HREADSDC,
   output logic 	    HRESPSDC, 
   output logic 	    HREADYSDC,

   //sd card interface
   // place the tristate drivers at the top.  this level
   // will use dedicated 1 direction ports.
   output logic 	    SDCmdOut,
   input logic 		    SDCmdIn,
   output logic 	    SDCmdOE,
   input logic 		    SDDatIn,
   output logic 	    SDCLK,

   // interrupt to PLIC
   output logic 	    SDCIntM);

  logic 		    initTrans;
  logic 		    RegRead;
  logic 		    RegWrite;
  logic [4:0] 		    HADDRDelay;


  // Register outputs
  logic [31:0] 		    CLKDiv;
  logic [2:0] 		    Command;
  logic [`XLEN-1:9] 	    Address;
  

  logic 		    SDCDone;
  
  logic [2:0] 		    ErrorCode;
  logic 		    InvalidCommand;
  logic 		    Done;
  logic 		    Busy;

  logic 		    StartCLKDivUpdate;
  logic 		    CLKDivUpdateEn;
  logic 		    SDCLKEN;
  
  
  

  // registers
  //| Offset | Name    | Size | Purpose                                        |
  //|--------+---------+------+------------------------------------------------|
  //|    0x0 | CLKDiv  |    4 | Divide HCLK to produce SDCLK                   |
  //|    0x4 | Status  |    4 | Provide status to software                     |
  //|    0x8 | Control |    4 | Send commands to SDC                           |
  //|    0xC | Size    |    4 | Size of data command (only 512 byte supported) |
  //|   0x10 | address |    8 | address of operation                           |
  //|   0x18 | data    |    8 | Data Bus interface                             |

  // Status contains
  // Status[0] busy
  // Status[1] done
  // Status[2] invalid command
  // Status[5:3] error code
  
  // control contains 3 bit command
  // control[2:0]
  // 000 nop op
  // xx1 initialize
  // 010 Write  no implemented
  // 100 Read
  // 110 Atomic read/write not implemented

  // size is fixed to 512. Read only
  
  
  // Currently using a mailbox style interface.   Data is passed through the Data register (0x10)
  // The card will support 3 operations
  // 1. initialize
  // 2. read
  // 3. write
  // all read and write operations will occur on 512 bytes (4096 bits) of data
  // starting at the 512 byte aligned address in the address register  This register
  // is the byte address.

  // currently does not support writes

  assign InitTrans = HREADY & HSELSDC & (HTRANS != 2'b00);
  assign RegRead = InitTrans & ~HWRITE;
  // AHBLite Spec has write data 1 cycle after write command
  flopr #(1) RegWriteReg(HCLK, ~HRESETn, InitTrans & HWRITE, RegWrite);
  
  flopr #(5) HADDRReg(HCLK, ~HRESETn, HADDR, HADDRDelay);
  
  assign StartCLKDivUpdate = HADDRDelay == '0 & RegWrite;
  
  flopenl #(32) CLKDivReg(HCLK, ~HRESETn, CLKDivUpdateEn, HWDATA[31:0], `SDCCLKDIV, CLKDiv);

  // Control reg
  flopenl #(3) CommandReg(HCLK, ~HRESETn, (HADDRDelay == 'h8 & RegWrite) | (SDCDone), 
			   SDCDone ? '0 : HWDATA[2:0], '0, Command);
  
  flopenr #(`XLEN-9) AddressReg(HCLK, ~HRESETn, (HADDRDelay == 'h10 & RegWrite),
			      HWDATA[`XLEN-1:9], Address);

  flopen #(`XLEN) DataReg(HCLK, (HADDRDelay == 'h18 & RegWrite) | (SDCDataValid),
			  SDCDataValid ? SDCReadData : HWDATA, ReadData);

  generate
    if(`XLEN == 64) begin
      always_comb
	case(HADDRDelay[4:2]) 
	  'h0: HREADSDC = {32'b0, CLKDiv};
	  'h4: HREADSDC = {`XLEN-6'b0, ErrorCode, InvalidCommand, Done, Busy};
	  'h8: HREADSDC = {`XLEN-3'b0, Command};
	  'hC: HREADSDC = 'h200;
	  'h10: HREADSDC = Address;
	  'h18: HREADSDC = ReadData;
	  default: HREADSDC = {32'b0, CLKDiv};
	endcase
    end  else begin
      always_comb
	case(HADDRDelay[4:2]) 
	  'h0: HREADSDC = CLKDiv;
	  'h4: HREADSDC = {ErrorCode, InvalidCommand, Done, Busy};
	  'h8: HREADSDC = Command;
	  'hC: HREADSDC = 'h200;
	  'h10: HREADSDC = Address[31:0];
	  'h14: HREADSDC = Address[63:32];	  
	  'h18: HREADSDC = ReadData[31:0];
	  'h1C: HREADSDC = ReadData[63:32];
	  default: HREADSDC = CLKDiv;
	endcase
    end
  endgenerate

  typedef enum {STATE_READY,

		// clock update states
		STATE_CLK_DIV1,
		STATE_CLK_DIV2,
		STATE_CLK_DIV3,
		STATE_CLK_DIV4,

		// restart SDC
		STATE_RESTART,

		// SDC operation
		STATE_PROCESS_CMD
		} statetype;


  statetype CurrState, NextState;
  
  always_ff @(posedge HCLK, posedge ~HRESETn)
    if (~HRESETn)    CurrState <= #1 STATE_READY;
    else CurrState <= #1 NextState;

  always_comb begin
    CLKDivUpdateEn = 1'b0;
    HREADYSDC = 1'b0;
    SDCLKEN = 1'b1;
    case (CurrState)

      STATE_READY : begin
	if (StartCLKDivUpdate)begin
	  NextState = STATE_CLK_DIV1;
	  HREADYSDC = 1'b0;
/* -----\/----- EXCLUDED -----\/-----
	end else if () begin
 -----/\----- EXCLUDED -----/\----- */
	  
	end else begin
	  NextState = STATE_READY;
	  HREADYSDC = 1'b1;
	end
      end
      STATE_CLK_DIV1: begin
	NextState = STATE_CLK_DIV2;
	SDCLKEN = 1'b0;
      end
      STATE_CLK_DIV2: begin
	NextState = STATE_CLK_DIV3;
	CLKDivUpdateEn = 1'b1;
	SDCLKEN = 1'b0;
      end
      STATE_CLK_DIV3: begin
	NextState = STATE_CLK_DIV4;
	SDCLKEN = 1'b0;
      end
      STATE_CLK_DIV4: begin
	NextState = STATE_READY;
      end
    endcase
  end
  
  
endmodule
	    

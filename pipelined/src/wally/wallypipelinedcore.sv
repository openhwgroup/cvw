///////////////////////////////////////////
// wallypipelinedcore.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Pipelined RISC-V Processor
// 
// Documentation: RISC-V System on Chip Design (Figure 4.1)
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

import cvw::*;  // global CORE-V-Wally parameters

module wallypipelinedcore (
   input  logic                  clk, reset,
   // Privileged
   input  logic                  MTimerInt, MExtInt, SExtInt, MSwInt,
   input  logic [63:0]           MTIME_CLINT, 
   // Bus Interface
   input  logic [AHBW-1:0]       HRDATA,
   input  logic                  HREADY, HRESP,
   output logic                  HCLK, HRESETn,
   output logic [PA_BITS-1:0]    HADDR,
   output logic [AHBW-1:0]       HWDATA,
   output logic [XLEN/8-1:0]     HWSTRB,
   output logic                  HWRITE,
   output logic [2:0]            HSIZE,
   output logic [2:0]            HBURST,
   output logic [3:0]            HPROT,
   output logic [1:0]            HTRANS,
   output logic                  HMASTLOCK
);

  logic                          StallF, StallD, StallE, StallM, StallW;
  logic                          FlushD, FlushE, FlushM, FlushW;
  logic                          RetM;
  logic TrapM;

  //  signals that must connect through DP
  logic                          IntDivE, W64E;
  logic                          CSRReadM, CSRWriteM, PrivilegedM;
  logic [1:0]                    AtomicM;
  logic [XLEN-1:0]               ForwardedSrcAE, ForwardedSrcBE;
  logic [XLEN-1:0] 			  SrcAM;
  logic [2:0]                    Funct3E;
  logic [31:0]                   InstrD;
  logic [31:0] 					 InstrM;
  logic [XLEN-1:0]               PCF, PCE, PCLinkE;
  logic [XLEN-1:0] 			  PCM;
  logic [XLEN-1:0]               CSRReadValW, MDUResultW;
  logic [XLEN-1:0]               UnalignedPCNextF, PCNext2F;
  logic [1:0] 					 MemRWM;
  logic 						 InstrValidM;
  logic                          InstrMisalignedFaultM;
  logic                          IllegalBaseInstrFaultD, IllegalIEUInstrFaultD;
  logic                          InstrPageFaultF, LoadPageFaultM, StoreAmoPageFaultM;
  logic                          LoadMisalignedFaultM, LoadAccessFaultM;
  logic                          StoreAmoMisalignedFaultM, StoreAmoAccessFaultM;
  logic                          InvalidateICacheM, FlushDCacheM;
  logic                          PCSrcE;
  logic                          CSRWriteFenceM;
  logic                          DivBusyE;
  logic                          LoadStallD, StoreStallD, MDUStallD, CSRRdStallD;
  logic                          SquashSCW;

  // floating point unit signals
  logic [2:0]                    FRM_REGW;
  logic [4:0]                    RdE, RdM, RdW;
  logic                          FPUStallD;
  logic                          FWriteIntE;
  logic [FLEN-1:0]               FWriteDataM;
  logic [XLEN-1:0]               FIntResM;  
  logic [XLEN-1:0]              FCvtIntResW; 
  logic                          FCvtIntW; 
  logic                          FDivBusyE;
  logic                          IllegalFPUInstrM;
  logic                          FRegWriteM;
  logic                          FCvtIntStallD;
  logic                          FpLoadStoreM;
  logic [4:0]                    SetFflagsM;
  logic [XLEN-1:0]               FIntDivResultW;

  // memory management unit signals
  logic                          ITLBWriteF;
  logic                          ITLBMissF;
  logic [XLEN-1:0]               SATP_REGW;
  logic                          STATUS_MXR, STATUS_SUM, STATUS_MPRV;
  logic  [1:0]                   STATUS_MPP, STATUS_FS;
  logic [1:0]                    PrivilegeModeW;
  logic [XLEN-1:0]               PTE;
  logic [1:0]                    PageType;
  logic                          sfencevmaM, WFIStallM;
  logic                          SelHPTW;

  // PMA checker signals
  var logic [XLEN-1:0]           PMPADDR_ARRAY_REGW[PMP_ENTRIES-1:0];
  var logic [7:0]                PMPCFG_ARRAY_REGW[PMP_ENTRIES-1:0];

  // IMem stalls
  logic                          IFUStallF;
  logic                          LSUStallM;

  // cpu lsu interface
  logic [2:0]                    Funct3M;
  logic [XLEN-1:0]               IEUAdrE;
  logic [XLEN-1:0]  WriteDataM;
  logic [XLEN-1:0]  IEUAdrM;  
  logic [LLEN-1:0]               ReadDataW;  
  logic                          CommittedM;

  // AHB ifu interface
  logic [PA_BITS-1:0]            IFUHADDR;
  logic [2:0]                    IFUHBURST;
  logic [1:0]                    IFUHTRANS;
  logic [2:0]                    IFUHSIZE;
  logic                          IFUHWRITE;
  logic                          IFUHREADY;
  
  // AHB LSU interface
  logic [PA_BITS-1:0]            LSUHADDR;
  logic [XLEN-1:0]               LSUHWDATA;
  logic [XLEN/8-1:0]             LSUHWSTRB;
  logic                          LSUHWRITE;
  logic                          LSUHREADY;
  
  logic                          BPPredWrongE, BPPredWrongM;
  logic                          DirPredictionWrongM;
  logic                          BTBPredPCWrongM;
  logic                          RASPredPCWrongM;
  logic                          PredictionInstrClassWrongM;
  logic [3:0]                    InstrClassM;
  logic                          InstrAccessFaultF, HPTWInstrAccessFaultM;
  logic [2:0]                    LSUHSIZE;
  logic [2:0]                    LSUHBURST;
  logic [1:0]                    LSUHTRANS;
  
  logic                          DCacheMiss;
  logic                          DCacheAccess;
  logic                          ICacheMiss;
  logic                          ICacheAccess;
  logic                          BreakpointFaultM, EcallFaultM;
  logic                          InstrDAPageFaultF;
  logic                          BigEndianM;
  logic                          FCvtIntE;
  logic                          CommittedF;
  logic 						 JumpOrTakenBranchM;
  
  // instruction fetch unit: PC, branch prediction, instruction cache
  ifu ifu(.clk, .reset,
    .StallF, .StallD, .StallE, .StallM, .StallW, .FlushD, .FlushE, .FlushM, .FlushW,
    // Fetch
    .HRDATA, .PCF, .IFUHADDR, .PCNext2F,
    .IFUStallF, .IFUHBURST, .IFUHTRANS, .IFUHSIZE, .IFUHREADY, .IFUHWRITE,
    .ICacheAccess, .ICacheMiss,
    // Execute
    .PCLinkE, .PCSrcE, .IEUAdrE, .PCE, .BPPredWrongE,  .BPPredWrongM, 
    // Mem
    .CommittedF, .UnalignedPCNextF, .InvalidateICacheM, .CSRWriteFenceM,
    .InstrD, .InstrM, .PCM, .InstrClassM, .DirPredictionWrongM, .JumpOrTakenBranchM,
    .BTBPredPCWrongM, .RASPredPCWrongM, .PredictionInstrClassWrongM,
    // Faults out
    .IllegalBaseInstrFaultD, .InstrPageFaultF, .IllegalIEUInstrFaultD, .InstrMisalignedFaultM,
    // mmu management
    .PrivilegeModeW, .PTE, .PageType, .SATP_REGW, .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV,
    .STATUS_MPP, .ITLBWriteF, .sfencevmaM, .ITLBMissF,
    // pmp/pma (inside mmu) signals. 
    .PMPCFG_ARRAY_REGW,  .PMPADDR_ARRAY_REGW, .InstrAccessFaultF, .InstrDAPageFaultF); 
    
  // integer execution unit: integer register file, datapath and controller
  ieu ieu(.clk, .reset,
     // Decode Stage interface
     .InstrD, .IllegalIEUInstrFaultD, .IllegalBaseInstrFaultD,
     // Execute Stage interface
     .PCE, .PCLinkE, .FWriteIntE, .FCvtIntE, .IEUAdrE, .IntDivE, .W64E,
     .Funct3E, .ForwardedSrcAE, .ForwardedSrcBE, 
     // Memory stage interface
     .SquashSCW, // from LSU
     .MemRWM, // read/write control goes to LSU
     .AtomicM, // atomic control goes to LSU
     .WriteDataM, // Write data to LSU
     .Funct3M, // size and signedness to LSU
     .SrcAM, // to privilege and fpu
     .RdE, .RdM, .FIntResM, .InvalidateICacheM, .FlushDCacheM,
     // Writeback stage
     .CSRReadValW, .MDUResultW, .FIntDivResultW, .RdW, .ReadDataW(ReadDataW[XLEN-1:0]),
     .InstrValidM, .FCvtIntResW, .FCvtIntW,
     // hazards
     .StallD, .StallE, .StallM, .StallW, .FlushD, .FlushE, .FlushM, .FlushW,
     .FCvtIntStallD, .LoadStallD, .MDUStallD, .CSRRdStallD, .PCSrcE,
     .CSRReadM, .CSRWriteM, .PrivilegedM, .CSRWriteFenceM, .StoreStallD); 

  lsu lsu(
    .clk, .reset, .StallM, .FlushM, .StallW, .FlushW,
    // CPU interface
    .MemRWM, .Funct3M, .Funct7M(InstrM[31:25]), .AtomicM,
    .CommittedM, .DCacheMiss, .DCacheAccess, .SquashSCW,            
    .FpLoadStoreM, .FWriteDataM, .IEUAdrE, .IEUAdrM, .WriteDataM,
    .ReadDataW, .FlushDCacheM,
    // connected to ahb (all stay the same)
    .LSUHADDR,  .HRDATA, .LSUHWDATA, .LSUHWSTRB, .LSUHSIZE, 
    .LSUHBURST, .LSUHTRANS, .LSUHWRITE, .LSUHREADY,
    // connect to csr or privilege and stay the same.
    .PrivilegeModeW, .BigEndianM,          // connects to csr
    .PMPCFG_ARRAY_REGW,     // connects to csr
    .PMPADDR_ARRAY_REGW,    // connects to csr
    // hptw keep i/o
    .SATP_REGW, // from csr
    .STATUS_MXR, // from csr
    .STATUS_SUM,  // from csr
    .STATUS_MPRV,  // from csr            
    .STATUS_MPP,  // from csr      
    .sfencevmaM,                   // connects to privilege
    .LoadPageFaultM,   // connects to privilege
    .StoreAmoPageFaultM, // connects to privilege
    .LoadMisalignedFaultM, // connects to privilege
    .LoadAccessFaultM,         // connects to privilege
    .HPTWInstrAccessFaultM,         // connects to privilege
    .StoreAmoMisalignedFaultM, // connects to privilege
    .StoreAmoAccessFaultM,     // connects to privilege
    .InstrDAPageFaultF,
    .PCF, .ITLBMissF, .PTE, .PageType, .ITLBWriteF, .SelHPTW,
    .LSUStallM);                    

  if(BUS_SUPPORTED) begin : ebu
    ebu ebu(// IFU connections
      .clk, .reset,
      // IFU interface
      .IFUHADDR,
      .IFUHBURST, 
      .IFUHTRANS, 
      .IFUHREADY,
      .IFUHSIZE,
      // LSU interface
      .LSUHADDR,
      .LSUHWDATA,
      .LSUHWSTRB,
      .LSUHSIZE,
      .LSUHBURST,
      .LSUHTRANS,
      .LSUHWRITE,
      .LSUHREADY,
      // BUS interface
      .HREADY, .HRESP, .HCLK, .HRESETn,
      .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HSIZE, .HBURST,
      .HPROT, .HTRANS, .HMASTLOCK);
  end

  // global stall and flush control  
  hazard  hzu(
    .BPPredWrongE, .CSRWriteFenceM, .RetM, .TrapM,
    .LoadStallD, .StoreStallD, .MDUStallD, .CSRRdStallD,
    .LSUStallM, .IFUStallF,
    .FCvtIntStallD, .FPUStallD,
    .DivBusyE, .FDivBusyE,
    .EcallFaultM, .BreakpointFaultM,
    .WFIStallM,
    // Stall & flush outputs
    .StallF, .StallD, .StallE, .StallM, .StallW,
    .FlushD, .FlushE, .FlushM, .FlushW);    

  // privileged unit
  if (ZICSR_SUPPORTED) begin:priv
    privileged priv(
      .clk, .reset,
      .FlushD, .FlushE, .FlushM, .FlushW, .StallD, .StallE, .StallM, .StallW,
      .CSRReadM, .CSRWriteM, .SrcAM, .PCM, .PCNext2F,
      .InstrM, .CSRReadValW, .UnalignedPCNextF,
      .RetM, .TrapM, .sfencevmaM,
      .InstrValidM, .CommittedM, .CommittedF,
      .FRegWriteM, .LoadStallD,
      .DirPredictionWrongM, .BTBPredPCWrongM, .BPPredWrongM,
      .RASPredPCWrongM, .PredictionInstrClassWrongM,
      .InstrClassM, .JumpOrTakenBranchM, .DCacheMiss, .DCacheAccess, .ICacheMiss, .ICacheAccess, .PrivilegedM,
      .InstrPageFaultF, .LoadPageFaultM, .StoreAmoPageFaultM,
      .InstrMisalignedFaultM, .IllegalIEUInstrFaultD, 
      .LoadMisalignedFaultM, .StoreAmoMisalignedFaultM,
      .MTimerInt, .MExtInt, .SExtInt, .MSwInt,
      .MTIME_CLINT, .IEUAdrM, .SetFflagsM,
      .InstrAccessFaultF, .HPTWInstrAccessFaultM, .LoadAccessFaultM, .StoreAmoAccessFaultM, .SelHPTW,
      .IllegalFPUInstrM, .PrivilegeModeW, .SATP_REGW,
      .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP, .STATUS_FS,
      .PMPCFG_ARRAY_REGW, .PMPADDR_ARRAY_REGW, 
      .FRM_REGW,.BreakpointFaultM, .EcallFaultM, .WFIStallM, .BigEndianM);
  end else begin
    assign CSRReadValW = 0;
    assign UnalignedPCNextF = PCNext2F;
    assign RetM = 0;
    assign TrapM = 0;
    assign WFIStallM = 0;
    assign sfencevmaM = 0;
    assign BigEndianM = 0;
  end

  // multiply/divide unit
  if (M_SUPPORTED) begin:mdu
    mdu mdu(.clk, .reset, .StallM, .StallW, .FlushE, .FlushM, .FlushW,
      .ForwardedSrcAE, .ForwardedSrcBE, 
      .Funct3E, .Funct3M, .IntDivE, .W64E,
      .MDUResultW, .DivBusyE); 
  end else begin // no M instructions supported
    assign MDUResultW = 0; 
    assign DivBusyE = 0;
  end

  // floating point unit
  if (F_SUPPORTED) begin:fpu
    fpu fpu(
      .clk, .reset,
      .FRM_REGW, // Rounding mode from CSR
      .InstrD, // instruction from IFU
      .ReadDataW(ReadDataW[FLEN-1:0]),// Read data from memory
      .ForwardedSrcAE, // Integer input being processed (from IEU)
      .StallE, .StallM, .StallW, // stall signals from HZU
      .FlushE, .FlushM, .FlushW, // flush signals from HZU
      .RdE, .RdM, .RdW, // which FP register to write to (from IEU)
      .STATUS_FS, // is floating-point enabled?
      .FRegWriteM, // FP register write enable
      .FpLoadStoreM,
      .ForwardedSrcBE, // Integer input for intdiv
      .Funct3E, .Funct3M, .IntDivE, .W64E, // Integer flags and functions
      .FPUStallD, // Stall the decode stage
      .FWriteIntE, .FCvtIntE, // integer register write enable, conversion operation
      .FWriteDataM, // Data to be written to memory
      .FIntResM, // data to be written to integer register
      .FCvtIntResW, // fp -> int conversion result to be stored in int register
      .FCvtIntW,   // fpu result selection
      .FDivBusyE, // Is the divide/sqrt unit busy (stall execute stage)
      .IllegalFPUInstrM, // Is the instruction an illegal fpu instruction
      .SetFflagsM,        // FPU flags (to privileged unit)
      .FIntDivResultW); 
  end else begin // no F_SUPPORTED or D_SUPPORTED; tie outputs low
    assign FPUStallD = 0;
    assign FWriteIntE = 0; 
    assign FCvtIntE = 0;
    assign FIntResM = 0;
    assign FCvtIntW = 0;
    assign FDivBusyE = 0;
    assign IllegalFPUInstrM = 1;
    assign SetFflagsM = 0;
    assign FpLoadStoreM = 0;
  end
  
endmodule

///////////////////////////////////////////
// pmachecker.sv
//
// Written: tfleming@hmc.edu & jtorrey@hmc.edu 20 April 2021
// Modified: 
//
// Purpose: Examines all physical memory accesses and identifies attributes of
//          the memory region accessed.
//          Can report illegal accesses to the trap unit and cause a fault.
// 
// Documentation: RISC-V System on Chip Design Chapter 8
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

module pmachecker import cvw::*;  #(parameter cvw_t P) (
  input  logic [P.PA_BITS-1:0] PhysicalAddress,
  input  logic [1:0]           Size,
  input  logic                 AtomicAccessM,  // Atomic access
  input  logic                 ExecuteAccessF, // Execute access 
  input  logic                 WriteAccessM,   // Write access 
  input  logic                 ReadAccessM,    // Read access
  input  logic [1:0]           PBMemoryType,     // PBMT field of PTE during TLB hit, or 00 otherwise
  output logic                 Cacheable, Idempotent, SelTIM,
  output logic                 PMAInstrAccessFaultF,
  output logic                 PMALoadAccessFaultM,
  output logic                 PMAStoreAmoAccessFaultM
);

  logic                        PMAAccessFault;
  logic                        AccessRW, AccessRWX, AccessRX;
  logic [11:0]                 SelRegions;
  logic                        AtomicAllowed;
  logic                        CacheableRegion, IdempotentRegion;

  // Determine what type of access is being made
  assign AccessRW  = ReadAccessM | WriteAccessM;
  assign AccessRWX = ReadAccessM | WriteAccessM | ExecuteAccessF;
  assign AccessRX  = ReadAccessM | ExecuteAccessF;

  // Determine which region of physical memory (if any) is being accessed
  adrdecs #(P) adrdecs(PhysicalAddress, AccessRW, AccessRX, AccessRWX, Size, SelRegions);

  // Only non-core RAM/ROM memory regions are cacheable. PBMT can override cachable; NC and IO are uncachable
  assign CacheableRegion = SelRegions[9] | SelRegions[8] | SelRegions[7];  // exclusion-tag: unused-cachable
  assign Cacheable = (PBMemoryType == 2'b00) ? CacheableRegion : 0;  

  // Nonidemdempotent means access could have side effect and must not be done speculatively or redundantly
  // I/O is nonidempotent.  PBMT can override PMA; NC is idempotent and IO is non-idempotent
  assign IdempotentRegion = SelRegions[11] | SelRegions[10] | SelRegions[9] | SelRegions[8] | SelRegions[7]; 
  assign Idempotent = (PBMemoryType == 2'b00) ? IdempotentRegion : (PBMemoryType == 2'b01);  // exclusion-tag: unused-idempotent
 
  // Atomic operations are only allowed on RAM
  assign AtomicAllowed = SelRegions[11] | SelRegions[9] | SelRegions[7];
  // Check if tightly integrated memories are selected
  assign SelTIM = SelRegions[11] | SelRegions[10];

  // Detect access faults
  assign PMAAccessFault          = (SelRegions[0]) & AccessRWX | AtomicAccessM & ~AtomicAllowed;  
  assign PMAInstrAccessFaultF    = ExecuteAccessF & PMAAccessFault;
  assign PMALoadAccessFaultM     = ReadAccessM    & PMAAccessFault;
  assign PMAStoreAmoAccessFaultM = WriteAccessM   & PMAAccessFault;
endmodule

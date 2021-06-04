//////////////////////////////////////////
// wally-constants.vh
//
// Written: tfleming@hmc.edu 4 March 2021
// Modified: Kmacsaigoren@hmc.edu 31 May 2021
//              Added constants for checking sv mode and changed existing constants to accomodate
//              both sv48 and sv39
//
// Purpose: Specify constants nexessary for different memory virtualization modes.
//              These are specific to sv49, defined in section 4.5 of the privileged spec.
//              However, despite different constants for different modes, the hardware helps distinguish between
//              each mode.
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

/*
// Virtual Memory Constants (sv48)
`define VPN_SEGMENT_BITS_RV64 9
`define VPN_BITS_RV64 36
`define PPN_HIGH_SEGMENT_BITS_RV64 17
`define PPN_BITS_RV64 44
`define PA_BITS_RV64 56
`define SVMODE_BITS_RV64 4
// Virtual Memory Constants (sv32)
`define VPN_SEGMENT_BITS_RV32 10
`define VPN_BITS_RV32 20
`define PPN_HIGH_SEGMENT_BITS_RV32 12
`define PPN_BITS_RV32 22
`define PA_BITS_RV32 34
`define SVMODE_BITS_RV32 1
*/

// Virtual Memory Constants
`define VPN_SEGMENT_BITS (`XLEN == 32 ? 10 : 9)
`define VPN_BITS (`XLEN==32 ? (2*`VPN_SEGMENT_BITS) : (4*`VPN_SEGMENT_BITS))
`define PPN_HIGH_SEGMENT_BITS (`XLEN==32 ? 12 : 17)
`define PPN_BITS (`XLEN==32 ? 22 : 44)
`define PA_BITS (`XLEN==32 ? 34 : 56)
`define SVMODE_BITS (`XLEN == 32 ? 1 : 4)

// constants to check SATP_MODE against
// defined in Table 4.3 of the privileged spec
`define NO_TRANSLATE 0
`define SV32 1
`define SV39 8
`define SV48 9

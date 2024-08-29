///////////////////////////////////////////
// divremsqrtroundsign.sv
//
// Written: kekim@hmc.edu,me@KatherineParry.com
// Modified: 19 May 2023
//
// Purpose: Sign calculation for rounding
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

module divremsqrtroundsign import cvw::*;  #(parameter cvw_t P) (
  input logic         Xs,     // x sign
  input logic         Ys,     // y sign
  input logic         Sqrt,   // sqrt oppertion? (when using divsqrt unit)
  input logic         DivOp,  // is divsqrt opperation
  output logic        Ms      // normalized result sign
);

  logic               Qs;     // divsqrt result sign

  // calculate divsqrt sign
  assign Qs = Xs^(Ys&~Sqrt);

  // Select sign for rounding calulation
  assign Ms = (Qs&DivOp);

endmodule

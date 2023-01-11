///////////////////////////////////////////
// simple_timer.sv
//
// Written: Ross Thompson September 20, 2021
// Modified: 
//
// Purpose: SD card controller
// 
// A component of the CORE-V Wally configurable RISC-V project.
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

`include "wally-config.vh"

module simple_timer #(parameter BUS_WIDTH = 4)
  (
   input logic [BUS_WIDTH-1:0] VALUE,
   input logic 		       START,
   output logic 	       FLAG,
   input logic 		       RST,
   input logic 		       CLK);


  logic [BUS_WIDTH-1:0]     count;
  logic timer_en;

  assign timer_en = count != 0;

  always_ff @(posedge CLK, posedge RST) begin
    if (RST) begin
      count <= '0;
    end else if (START) begin
      count <= VALUE - 1'b1;
    end else if(timer_en) begin
      count <= count - 1'b1;
    end
  end

  assign FLAG = count != 0;
  
endmodule
   

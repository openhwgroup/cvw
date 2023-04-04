#///////////////////////////////////////////
#// coverage-exclusions-rv64gc.do
#//
#// Written: David_Harris@hmc.edu 19 March 2023
#//
#// Purpose: Set of exclusions from coverage for rv64gc configuration
#//          For example, signals hardwired to 0 should not be checked for toggle coverage
#//
#// A component of the CORE-V-WALLY configurable RISC-V project.
#// 
#// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
#//
#// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#//
#// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
#// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
#// may obtain a copy of the License at
#//
#// https://solderpad.org/licenses/SHL-2.1/
#//
#// Unless required by applicable law or agreed to in writing, any work distributed under the 
#// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
#// either express or implied. See the License for the specific language governing permissions 
#// and limitations under the License.
#////////////////////////////////////////////////////////////////////////////////////////////////

# This file should be a last resort.  It's preferable to put 
# // coverage off 
# statements inline with the code whenever possible.

# LZA (i<64) statement confuses coverage tool 
# This is ugly to exlcude the whole file - is there a better option?  // coverage off isn't working
coverage exclude -srcfile lzc.sv 


######################
# Toggle exclusions
#   Not used because toggle coverage isn't measured
######################

# Exclude DivBusyE from all design units because rv64gc uses the fdivsqrt unit for integer division
#coverage exclude -togglenode DivBusyE -du *
# Exclude QuotM and RemM from MDU because rv64gc uses the fdivsqrt rather tha div unit for integer division
#coverage exclude -togglenode /dut/core/mdu/mdu/QuotM
#coverage exclude -togglenode /dut/core/mdu/mdu/RemM

# StallFCause is hardwired to 0
#coverage exclude -togglenode /dut/core/hzu/StallFCause


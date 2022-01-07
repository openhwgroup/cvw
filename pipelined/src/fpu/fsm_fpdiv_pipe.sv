///////////////////////////////////////////
//
// Written: James Stine
// Modified: 9/28/2021
//
// Purpose: FSM for floating point divider/square root unit (Goldschmidt)
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

module fsm_fpdiv_pipe (
   input logic 	      clk,
   input logic 	      reset,
   input logic 	      start,
   input logic 	      op_type,
   input logic 	      P,
   output logic       done,
   output logic       load_preload,
   output logic       load_rega, 
   output logic       load_regb, 
   output logic       load_regc, 
   output logic       load_regd,
   output logic       load_regr,
   output logic       load_regs,
   output logic       load_regp,
   output logic [2:0] sel_muxa, 
   output logic [2:0] sel_muxb, 
   output logic       sel_muxr,
   output logic       divBusy	   
   );

   // div64 : S1-S14 (14 cycles)
   // sqrt64 : S15-S35 (21 cycles)
   // div32: S36-S47 (12 cycles)
   // sqrt32 : S48-S64 (17 cycles)
   typedef enum       logic [6:0] {S0, S1, S2, S3, S4, S5, S6, S7, S8, S9,
				   S10, S11, S12, S13, S14, S15, S16, S17, S18, S19,
				   S20, S21, S22, S23, S24, S25, S26, S27, S28, S29,
				   S30, S31, S32, S33, S34, S35, S36, S37, S38, S39,
				   S40, S41, S42, S43, S44, S45, S46, S47, S48, S49,
				   S50, S51, S52, S53, S54, S55, S56, S57, S58, S59,
				   S60, S61, S62, S63, S64, S65, S66} statetype;
   
   statetype current_state, next_state;   
   
   always @(posedge clk)
     begin
	if (reset == 1'b1)
	  current_state <= S0;
	else
	  current_state <= next_state;
     end

   always @(*)
     begin
 	case(current_state)
	  S0:  // iteration 0
	    begin
	       if (start==1'b0)
		 begin
		    done = 1'b0;
		    divBusy = 1'b0;
		    load_preload = 1'b0;
		    load_rega = 1'b0;
		    load_regb = 1'b0;
		    load_regc = 1'b0;
		    load_regd = 1'b0;
		    load_regr = 1'b0;
		    load_regs = 1'b0;
		    load_regp = 1'b0;		    
		    sel_muxa = 3'b000;
		    sel_muxb = 3'b000;
		    sel_muxr = 1'b0;
		    next_state = S0;
		 end // if (start==1'b0)
	       else
		 begin
		    done = 1'b0;
		    divBusy = 1'b1;
		    load_preload = 1'b1;		    
		    load_rega = 1'b0;
		    load_regb = 1'b0;
		    load_regc = 1'b0;
		    load_regd = 1'b0;
		    load_regr = 1'b0;
		    load_regs = 1'b0;
		    load_regp = 1'b0;		    
		    sel_muxa = 3'b000;
		    sel_muxb = 3'b000;
		    sel_muxr = 1'b0;
		    next_state = S66;
		 end 
	    end // case: S0
	  S66:
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b0;		    
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S65;
	    end // if (start==1'b0)
	  S65:
	    begin
	       if (op_type==1'b0 && P==1'b0) 
		 begin
		    done = 1'b0;
		    divBusy = 1'b1;
		    load_preload = 1'b0;		    
		    load_rega = 1'b1;
		    load_regb = 1'b0;
		    load_regc = 1'b1;
		    load_regd = 1'b0;		    
		    load_regr = 1'b0;
		    load_regs = 1'b0;		    
		    load_regp = 1'b1;		    		    
		    sel_muxa = 3'b010;
		    sel_muxb = 3'b000;		    
		    sel_muxr = 1'b0;
		    next_state = S1;
		 end 
	       else if (op_type==1'b0 && P==1'b1) 
		 begin
		    done = 1'b0;
		    divBusy = 1'b1;
		    load_preload = 1'b0;		    
		    load_rega = 1'b1;
		    load_regb = 1'b0;
		    load_regc = 1'b1;
		    load_regd = 1'b0;		    
		    load_regr = 1'b0;
		    load_regs = 1'b0;		    
		    load_regp = 1'b1;		    		    
		    sel_muxa = 3'b010;
		    sel_muxb = 3'b000;		    
		    sel_muxr = 1'b0;
		    next_state = S36;
		 end 
	       else if (op_type==1'b1 && P==1'b0) 
		 begin
		    done = 1'b0;
		    divBusy = 1'b1;
		    load_preload = 1'b0;		    
		    load_rega = 1'b0;
		    load_regb = 1'b0;
		    load_regc = 1'b0;
		    load_regd = 1'b1;		    
		    load_regr = 1'b0;
		    load_regs = 1'b0;		    
		    load_regp = 1'b1;		    		    
		    sel_muxa = 3'b010;
		    sel_muxb = 3'b001;		    
		    sel_muxr = 1'b0;
		    next_state = S15;
		 end 
	       else if (op_type==1'b1 && P==1'b1) 
		 begin
		    done = 1'b0;
		    divBusy = 1'b1;
		    load_preload = 1'b0;		    
		    load_rega = 1'b0;
		    load_regb = 1'b0;
		    load_regc = 1'b0;
		    load_regd = 1'b1;		    
		    load_regr = 1'b0;
		    load_regs = 1'b0;		    
		    load_regp = 1'b1;		    		    
		    sel_muxa = 3'b010;
		    sel_muxb = 3'b001;		    
		    sel_muxr = 1'b0;
		    next_state = S48;
		 end 
	       else
		 begin
		    done = 1'b0;
		    divBusy = 1'b0;
		    load_preload = 1'b0;		    
		    load_rega = 1'b0;
		    load_regb = 1'b0;
		    load_regc = 1'b0;
		    load_regd = 1'b0;
		    load_regr = 1'b0;
		    load_regs = 1'b0;
		    load_regp = 1'b0;		    
		    sel_muxa = 3'b000;
		    sel_muxb = 3'b000;
		    sel_muxr = 1'b0;
		    next_state = S0;
		 end   
	    end // case: S0
	  // div64
	  S1:
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b001;
	       sel_muxb = 3'b001;		    
	       sel_muxr = 1'b0;	
	       next_state = S2;
	    end // case: S1
	  S2: // iteration 1	  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
		    load_preload = 1'b0;	       
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b010;
	       sel_muxr = 1'b0;
	       next_state = S3;
	    end
	  S3:
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S4;
	    end
	  S4: // iteration 2
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b010;
	       sel_muxr = 1'b0;
	       next_state = S5;
	    end
	  S5:
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;  // add
	       next_state = S6;
	    end
	  S6: // iteration 3
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;	       
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b010;
	       sel_muxr = 1'b0;
	       next_state = S7;
	    end
	  S7:
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S8;
	    end // case: S7
	  S8:
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S9;
	    end // case: S7	  
	  S9: // q,qm,qp
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b1;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S10;
	    end // case: S9
	  S10:  // rem
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;	   
	       load_preload = 1'b0;    
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b1;
	       next_state = S11;
	    end 	  	  
	  S11:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b1;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b1;
	       next_state = S12;
	    end // case: S11
	  S12:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S13;
	    end 	  	  
	  S13:  
	    begin
	       done = 1'b1;
	       divBusy = 1'b0;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S14;
	    end 
	  S14:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b0;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b0;
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S0;
	    end 
	  // sqrt64
	  S15:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S16;
	    end 
	  S16:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b001;
	       sel_muxb = 3'b100;
	       sel_muxr = 1'b0;
	       next_state = S17;
	    end
	  S17:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b010;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S18;
	    end 
	  S18:  // iteration 1
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b1;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S19;
	    end 
	  S19:  // iteration 1
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S20;
	    end	  
	  S20:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b100;
	       sel_muxb = 3'b010;
	       sel_muxr = 1'b0;
	       next_state = S21;
	    end
	  S21:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S22;
	    end
	  S22:  // iteration 2
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b1;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S23;
	    end // case: S18
	  S23:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S24;
	    end	  
	  S24:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b100;
	       sel_muxb = 3'b010;
	       sel_muxr = 1'b0;
	       next_state = S25;
	    end
	  S25:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S26;
	    end
	  S26:  // iteration 3
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b1;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S27;
	    end // case: S21
	  S27: 
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S28;
	    end	  
	  S28:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b100;
	       sel_muxb = 3'b010;
	       sel_muxr = 1'b0;
	       next_state = S29;
	    end
	  S29:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S30;
	    end // case: S23
	  S30: // q,qm,qp
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b1;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S31;
	    end 	  
	  S31:  // rem
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b110;
	       sel_muxr = 1'b1;
	       next_state = S32;
	    end // case: S25
	  S32:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b1;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b110;
	       sel_muxr = 1'b1;
	       next_state = S33;
	    end 
	  S33:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S34;
	    end 	  	  
	  S34:  // done
	    begin
	       done = 1'b1;
	       divBusy = 1'b0;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S35;
	    end 
	  S35:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b0;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b0;
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S0;
	    end 	  
	  // div32
	  S36: 
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b001;
	       sel_muxb = 3'b001;		    
	       sel_muxr = 1'b0;	
	       next_state = S37;
	    end // case: S1
	  S37: // iteration 1	  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b010;
	       sel_muxr = 1'b0;
	       next_state = S38;
	    end
	  S38:
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S39;
	    end
	  S39: // iteration 2
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b010;
	       sel_muxr = 1'b0;
	       next_state = S40;
	    end
	  S40:
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;  
	       next_state = S41;
	    end
	  S41:
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S42;
	    end 	  
	  S42: // q,qm,qp
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b1;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S43;
	    end // case: S9
	  S43:  // rem
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b1;
	       next_state = S44;
	    end 	  	  
	  S44:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b1;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b1;
	       next_state = S45;
	    end // case: S11
	  S45:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S46;
	    end 	  	  
	  S46:  // done
	    begin
	       done = 1'b1;
	       divBusy = 1'b0;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S47;
	    end 
	  S47:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b0;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b0;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S0;
	    end 	  
	  // sqrt32
	  S48:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S49;
	    end 
	  S49:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b001;
	       sel_muxb = 3'b100;
	       sel_muxr = 1'b0;
	       next_state = S50;
	    end
	  S50:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b010;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S51;
	    end 
	  S51:  // iteration 1
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b1;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S52;
	    end 
	  S52:  // iteration 1
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S53;
	    end	  
	  S53:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b100;
	       sel_muxb = 3'b010;
	       sel_muxr = 1'b0;
	       next_state = S54;
	    end
	  S54:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S55;
	    end
	  S55:  // iteration 2
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b1;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S56;
	    end // case: S18
	  S56:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S57;
	    end	  
	  S57:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b100;
	       sel_muxb = 3'b010;
	       sel_muxr = 1'b0;
	       next_state = S58;
	    end
	  S58:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S59;
	    end
	  S59: // q,qm,qp
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b1;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S60;
	    end 	  
	  S60:  // rem
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b110;
	       sel_muxr = 1'b1;
	       next_state = S61;
	    end // case: S25
	  S61:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b1;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b110;
	       sel_muxr = 1'b1;
	       next_state = S62;
	    end // case: S34
	  S62:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S63;
	    end 	  	  
	  S63:  // done
	    begin
	       done = 1'b1;
	       divBusy = 1'b0;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S64;
	    end // case: S34
	  S64: 
	    begin
	       done = 1'b0;
	       divBusy = 1'b0;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b0;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S0;
	    end 	  	  
	  default: 
	    begin
	       done = 1'b0;
	       divBusy = 1'b0;
	       load_preload = 1'b0;	       
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    
	       load_regp = 1'b0;
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S0;
	    end
	endcase // case(current_state)	
     end // always @ (current_state or X)   

endmodule // fsm

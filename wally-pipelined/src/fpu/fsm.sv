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

module fsm (
   input logic 	      clk,
   input logic 	      reset,
   input logic 	      start,
   input logic 	      op_type,
   output logic       done, 
   output logic       load_rega, 
   output logic       load_regb, 
   output logic       load_regc, 
   output logic       load_regd,
   output logic       load_regr,
   output logic       load_regs,
   output logic [2:0] sel_muxa, 
   output logic [2:0] sel_muxb, 
   output logic       sel_muxr, 
   output logic       divBusy	   
   );

   typedef enum       logic [4:0] {S0, S1, S2, S3, S4, S5, S6, S7, S8, S9,
				   S10, S11, S12, S13, S14, S15, S16, S17, S18, S19,
				   S20, S21, S22, S23, S24, S25, S26, S27, S28, S29,
				   S30} statetype;
   
   statetype current_state, next_state;
   
   always @(negedge clk)
     begin
	if (reset == 1'b1)
	  current_state = S0;
	else
	  current_state = next_state;
     end

   always_comb
     begin
 	case(current_state)
	  S0:  // iteration 0
	    begin
	       if (start==1'b0)
		 begin
		    done = 1'b0;
		    divBusy = 1'b0;	
		    load_rega = 1'b0;
		    load_regb = 1'b0;
		    load_regc = 1'b0;
		    load_regd = 1'b0;
		    load_regr = 1'b0;
		    load_regs = 1'b0;
		    sel_muxa = 3'b000;
		    sel_muxb = 3'b000;
		    sel_muxr = 1'b0;
		    next_state = S0;
		 end 
	       else if (start==1'b1 && op_type==1'b0) 
		 begin
		    done = 1'b0;
		    divBusy = 1'b1;	
		    load_rega = 1'b0;
		    load_regb = 1'b1;
		    load_regc = 1'b0;
		    load_regd = 1'b0;		    
		    load_regr = 1'b0;
		    load_regs = 1'b0;		    		    
		    sel_muxa = 3'b001;
		    sel_muxb = 3'b001;		    
		    sel_muxr = 1'b0;
		    next_state = S1;
		 end // if (start==1'b1 && op_type==1'b0)
	       else if (start==1'b1 && op_type==1'b1) 
		 begin
		    done = 1'b0;
		    divBusy = 1'b1;
		    load_rega = 1'b0;
		    load_regb = 1'b1;
		    load_regc = 1'b0;
		    load_regd = 1'b0;		    
		    load_regr = 1'b0;
		    load_regs = 1'b0;		    		    
		    sel_muxa = 3'b010;
		    sel_muxb = 3'b000;		    
		    sel_muxr = 1'b0;
		    next_state = S13;
		 end 	   
	       else
		 begin
		    done = 1'b0;
		    divBusy = 1'b0;
		    load_rega = 1'b0;
		    load_regb = 1'b0;
		    load_regc = 1'b0;
		    load_regd = 1'b0;		    
		    load_regr = 1'b0;
		    load_regs = 1'b0;		    		    
		    sel_muxa = 3'b000;
		    sel_muxb = 3'b000;		    
		    sel_muxr = 1'b0;
		    next_state = S0;
		 end
	    end // case: S0
	  S1:
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    	       
	       sel_muxa = 3'b010;
	       sel_muxb = 3'b000;		    
	       sel_muxr = 1'b0;	
	       next_state = S2;
	    end	  
	  S2: // iteration 1
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S3;
	    end
	  S3:
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b010;
	       sel_muxr = 1'b0;
	       next_state = S4;
	    end
	  S4: // iteration 2
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S5;
	    end
	  S5:
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b010;
	       sel_muxr = 1'b0;  // add
	       next_state = S6;
	    end
	  S6: // iteration 3
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S8;
	    end
	  S7:
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b010;
	       sel_muxr = 1'b0;
	       next_state = S8;
	    end // case: S7
	  S8: // q,qm,qp
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S9;
	    end 
	  S9:  // rem
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b1;
	       load_regs = 1'b0;  
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b1;
	       next_state = S10;
	    end 	  
	  S10:  // done
	    begin
	       done = 1'b1;
	       divBusy = 1'b0;
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S0;
	    end 
	  S13:  // start of sqrt path
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b1;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       sel_muxa = 3'b010;
	       sel_muxb = 3'b001;
	       sel_muxr = 1'b0;
	       next_state = S14;
	    end
	  S14:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    	       
	       sel_muxa = 3'b001;
	       sel_muxb = 3'b100;
	       sel_muxr = 1'b0;
	       next_state = S15;
	    end 
	  S15:  // iteration 1
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S16;
	    end
	  S16:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b1;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S17;
	    end
	  S17:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    	       
	       sel_muxa = 3'b100;
	       sel_muxb = 3'b010;
	       sel_muxr = 1'b0;
	       next_state = S18;
	    end
	  S18:  // iteration 2
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S19;
	    end
	  S19:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b1;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S20;
	    end
	  S20:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    	       
	       sel_muxa = 3'b100;
	       sel_muxb = 3'b010;
	       sel_muxr = 1'b0;
	       next_state = S21;
	    end
	  S21:  // iteration 3
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b0;
	       load_regb = 1'b1;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    	       
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S22;
	    end
	  S22:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b1;
	       load_regr = 1'b0;
	       load_regs = 1'b0;
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b011;
	       sel_muxr = 1'b0;
	       next_state = S23;
	    end
	  S23:  
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b1;
	       load_regb = 1'b0;
	       load_regc = 1'b1;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    	       
	       sel_muxa = 3'b100;
	       sel_muxb = 3'b010;
	       sel_muxr = 1'b0;
	       next_state = S24;
	    end 
	  S24: // q,qm,qp
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;
	       load_regr = 1'b0;
	       load_regs = 1'b1;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S25;
	    end 	  
	  S25:  // rem
	    begin
	       done = 1'b0;
	       divBusy = 1'b1;
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b1;
	       load_regs = 1'b0;  
	       sel_muxa = 3'b011;
	       sel_muxb = 3'b110;
	       sel_muxr = 1'b1;
	       next_state = S26;
	    end 
	  S26:  // done
	    begin
	       done = 1'b1;
	       divBusy = 1'b0;
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S0;
	    end 
	  default: 
	    begin
	       done = 1'b0;
	       divBusy = 1'b0;
	       load_rega = 1'b0;
	       load_regb = 1'b0;
	       load_regc = 1'b0;
	       load_regd = 1'b0;	       
	       load_regr = 1'b0;
	       load_regs = 1'b0;		    	       
	       sel_muxa = 3'b000;
	       sel_muxb = 3'b000;
	       sel_muxr = 1'b0;
	       next_state = S0;
	    end
	endcase // case(current_state)	
     end // always @ (current_state or X)   

endmodule // fsm

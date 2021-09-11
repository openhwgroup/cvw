module fsm (

   input logic 			clk,
   input logic 			reset,
   input logic 			start,
   input logic  		op_type,
   output logic 		done,      // End of cycles
   output logic 		load_rega, // enable for regA
   output logic 		load_regb, // enable for regB
   output logic 		load_regc, // enable for regC
   output logic 		load_regd, // enable for regD
   output logic 		load_regr, // enable for rem
   output logic 		load_regs, // enable for q,qm,qp 
   output logic [2:0] 	sel_muxa,  // Select muxA
   output logic [2:0] 	sel_muxb,  // Select muxB
   output logic 		sel_muxr,  // Select rem mux
   output logic			divBusy	   // calculation is happening
   );


   reg [4:0] 	CURRENT_STATE;
   reg [4:0] 	NEXT_STATE;   

   parameter [4:0] 
     S0=5'd0, S1=5'd1, S2=5'd2,
     S3=5'd3, S4=5'd4, S5=5'd5,
     S6=5'd6, S7=5'd7, S8=5'd8,
     S9=5'd9, S10=5'd10,
     S13=5'd13, S14=5'd14, S15=5'd15,     
     S16=5'd16, S17=5'd17, S18=5'd18,
     S19=5'd19, S20=5'd20, S21=5'd21,
     S22=5'd22, S23=5'd23, S24=5'd24,
     S25=5'd25, S26=5'd26, S27=5'd27,
     S28=5'd28, S29=5'd29, S30=5'd30;
   
   always @(negedge clk)
     begin
	if(reset==1'b1)
	  CURRENT_STATE=S0;
	else
	  CURRENT_STATE=NEXT_STATE;
     end

   always @(*)
     begin
 	case(CURRENT_STATE)
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
		    NEXT_STATE = S0;
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
		    NEXT_STATE = S1;
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
		    NEXT_STATE = S13;
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
		    NEXT_STATE = S0;
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
	       NEXT_STATE = S2;
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
	       NEXT_STATE = S3;
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
	       NEXT_STATE = S4;
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
	       NEXT_STATE = S5;
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
	       NEXT_STATE = S6;
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
	       NEXT_STATE = S8;
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
	       NEXT_STATE = S8;
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
	       NEXT_STATE = S9;
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
	       NEXT_STATE = S10;
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
	       NEXT_STATE = S0;
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
	       NEXT_STATE = S14;
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
	       NEXT_STATE = S15;
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
	       NEXT_STATE = S16;
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
	       NEXT_STATE = S17;
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
	       NEXT_STATE = S18;
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
	       NEXT_STATE = S19;
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
	       NEXT_STATE = S20;
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
	       NEXT_STATE = S21;
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
	       NEXT_STATE = S22;
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
	       NEXT_STATE = S23;
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
	       NEXT_STATE = S24;
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
	       NEXT_STATE = S25;
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
	       NEXT_STATE = S26;
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
	       NEXT_STATE = S0;
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
	       NEXT_STATE = S0;
	    end
	endcase // case(CURRENT_STATE)	
     end // always @ (CURRENT_STATE or X)   

endmodule // fsm

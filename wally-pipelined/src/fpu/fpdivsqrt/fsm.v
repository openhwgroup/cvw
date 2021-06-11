module fsm_fpdivsqrt (done, load_rega, load_regb, load_regc, 
		      load_regd, load_regr, load_regs,
		      load_regp,
		      sel_muxa, sel_muxb, sel_muxr, 
		      clk, reset, start, error, op_type, P);

   input 	clk;
   input 	reset;
   input 	start;
   input 	error;
   input  	op_type;
   input 	P;   
   
   output       done;      
   output       load_rega;
   output       load_regb;
   output       load_regc;
   output 	load_regd;   
   output 	load_regr;
   output 	load_regs;
   output 	load_regp;   
   
   output [2:0] sel_muxa;
   output [2:0] sel_muxb;
   output 	sel_muxr;

   reg 		done;      // End of cycles
   reg 		load_rega; // enable for regA
   reg 		load_regb; // enable for regB
   reg 		load_regc; // enable for regC
   reg 		load_regd; // enable for regD
   reg 		load_regr; // enable for rem
   reg 		load_regs; // enable for q,qm,qp
   reg 		load_regp; // enable for pipe stage
   reg [2:0] 	sel_muxa;  // Select muxA
   reg [2:0] 	sel_muxb;  // Select muxB
   reg 		sel_muxr;  // Select rem mux

   reg [5:0] 	CURRENT_STATE;
   reg [5:0] 	NEXT_STATE;   

   parameter [5:0]
     // div 64-bit
     S0=6'd0, S1=6'd1, S2=6'd2,
     S3=6'd3, S4=6'd4, S5=6'd5,
     S6=6'd6, S7=6'd7, S8=6'd8,
     S9=6'd9, S10=6'd10, S11=6'd11,
     S12=6'd12, S13=6'd13,
     // sqrt 64-bit
     S14=6'd14, S15=6'd15,     
     S16=6'd16, S17=6'd17, S18=6'd18,
     S19=6'd19, S20=6'd20, S21=6'd21,
     S22=6'd22, S23=6'd23, S24=6'd24,
     S25=6'd25, S26=6'd26, S27=6'd27,
     S28=6'd28, S29=6'd29, S30=6'd30,
     S31=6'd31, S32=6'd32, S33=6'd33, 
     S34=6'd34,
     // div 32-bit
     S35=6'd35,     
     S36=6'd36, S37=6'd37,
     S38=6'd38, S39=6'd39, S40=6'd40,
     S41=6'd41, S42=6'd42, S43=6'd43,
     S44=6'd44, S45=6'd45, 
     // sqrt 32-bit
     S46=6'd46, S47=6'd47, S48=6'd48,
     S49=6'd49, S50=6'd50, S51=6'd51,
     S52=6'd52, S53=6'd53, S54=6'd54,
     S55=6'd55, S56=6'd56, S57=6'd57,
     S58=6'd58, S59=6'd59, S60=6'd60,
     S61=6'd61, S62=6'd62, S63=6'd63;
   
   always @(posedge clk)
     begin
	if(reset==1'b1)
	  CURRENT_STATE<=S0;
	else
	  CURRENT_STATE<=NEXT_STATE;
     end

   always @(*)
     begin
 	case(CURRENT_STATE)
	  S0:  // iteration 0
	    begin
	       if (start==1'b0)
		 begin
		    done = 1'b0;
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
		    NEXT_STATE <= S0;
		 end 
	       else if (start==1'b1 && op_type==1'b0 && P==1'b0) // iteration 0 div
		 begin
		    done = 1'b0;
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
		    NEXT_STATE <= S1;
		 end // if (start==1'b1 && op_type==1'b0)
	       else if (start==1'b1 && op_type==1'b0 && P==1'b1) // iteration 0 div
		 begin
		    done = 1'b0;
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
		    NEXT_STATE <= S35;
		 end // if (start==1'b1 && op_type==1'b0 && P==1'b1)	       
	       else if (start==1'b1 && op_type==1'b1 && P==1'b0) // iteration 0 sqrt
		 begin
		    done = 1'b0;
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
		    NEXT_STATE <= S15;
		 end // if (start==1'b1 && op_type==1'b1 && P==1'b0)
	       else if (start==1'b1 && op_type==1'b1 && P==1'b1) // iteration 0 sqrt
		 begin
		    done = 1'b0;
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
		    NEXT_STATE <= S46;
		 end // if (start==1'b1 && op_type==1'b1 && P==1'b1)	       
	    end // case: S0
	  S1:
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S2;
	    end // case: S1
	  S2: // iteration 1	  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S3;
	    end
	  S3:
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S4;
	    end
	  S4: // iteration 2
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S5;
	    end
	  S5:
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S6;
	    end
	  S6: // iteration 3
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S7;
	    end
	  S7:
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S8;
	    end // case: S7
	  S8:
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S9;
	    end // case: S7	  
	  S9: // q,qm,qp
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S10;
	    end // case: S9
	  S10:  // rem
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S11;
	    end 	  	  
	  S11:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S12;
	    end // case: S11
	  S12:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S13;
	    end 	  	  
	  S13:  // done
	    begin
	       done = 1'b1;
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
	       NEXT_STATE <= S0;
	    end // case: S13
	  // SQRT P = 0	  	  
	  S15:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S16;
	    end 
	  S16:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S17;
	    end
	  S17:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S18;
	    end 
	  S18:  // iteration 1
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S19;
	    end // case: S15
	  S19:  // iteration 1
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S20;
	    end	  
	  S20:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S21;
	    end
	  S21:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S22;
	    end
	  S22:  // iteration 2
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S23;
	    end // case: S18
	  S23:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S24;
	    end	  
	  S24:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S25;
	    end
	  S25:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S26;
	    end
	  S26:  // iteration 3
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S27;
	    end // case: S21
	  S27: 
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S28;
	    end	  
	  S28:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S29;
	    end
	  S29:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S30;
	    end // case: S23
	  S30: // q,qm,qp
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S31;
	    end 	  
	  S31:  // rem
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S32;
	    end // case: S25
	  S32:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S33;
	    end // case: S34
	  S33:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S34;
	    end 	  	  
	  S34:  // done
	    begin
	       done = 1'b1;
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
	       NEXT_STATE <= S0;
	    end // case: S34
	  // DIV P = 1	  
	  S35: 
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S36;
	    end // case: S1
	  S36: // iteration 1	  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S37;
	    end
	  S37:
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S38;
	    end
	  S38: // iteration 2
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S39;
	    end
	  S39:
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S40;
	    end
	  S40:
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S41;
	    end 	  
	  S41: // q,qm,qp
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S42;
	    end // case: S9
	  S42:  // rem
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S43;
	    end 	  	  
	  S43:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S44;
	    end // case: S11
	  S44:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S45;
	    end 	  	  
	  S45:  // done
	    begin
	       done = 1'b1;
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
	       NEXT_STATE <= S0;
	    end // case: S45
	  // SQRT P = 1
	  S46:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S47;
	    end 
	  S47:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S48;
	    end
	  S48:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S49;
	    end 
	  S49:  // iteration 1
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S50;
	    end // case: S15
	  S50:  // iteration 1
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S51;
	    end	  
	  S51:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S52;
	    end
	  S52:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S53;
	    end
	  S53:  // iteration 2
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S54;
	    end // case: S18
	  S54:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S55;
	    end	  
	  S55:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S56;
	    end
	  S56:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S57;
	    end
	  S57: // q,qm,qp
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S58;
	    end 	  
	  S58:  // rem
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S59;
	    end // case: S25
	  S59:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S60;
	    end // case: S34
	  S60:  
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S61;
	    end 	  	  
	  S61:  // done
	    begin
	       done = 1'b1;
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
	       NEXT_STATE <= S0;
	    end // case: S34	  
	  // DEFAULT
	  default: 
	    begin
	       done = 1'b0;
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
	       NEXT_STATE <= S0;
	    end
	endcase // case(CURRENT_STATE)	
     end // always @ (CURRENT_STATE or X)   

endmodule // fsm

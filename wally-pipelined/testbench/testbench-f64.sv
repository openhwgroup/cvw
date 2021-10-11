// testbench
module testbench ();

   logic [63:0] op1;		
   logic [63:0] op2;
   logic [2:0] 	FOpCtrlE;   
   logic [2:0] 	FrmE;
   logic 	op_type;	
   logic 	FmtE;   		
   logic 	OvEn;		
   logic 	UnEn;   	

   logic 	XSgnE, YSgnE, ZSgnE;
   logic 	XSgnM, YSgnM;     
   logic [10:0] XExpE, YExpE, ZExpE;
   logic [10:0] XExpM, YExpM, ZExpM;
   logic [52:0] XManE, YManE, ZManE;
   logic [52:0] XManM, YManM, ZManM;

   logic [10:0] BiasE;
   logic 	XNaNE, YNaNE, ZNaNE;           
   logic 	XNaNM, YNaNM, ZNaNM;           
   logic 	XSNaNE, YSNaNE, ZSNaNE;        
   logic 	XSNaNM, YSNaNM, ZSNaNM;        
   logic 	XDenormE, YDenormE, ZDenormE;  
   logic 	XZeroE, YZeroE, ZZeroE;        
   logic 	XZeroM, YZeroM, ZZeroM;        
   logic 	XInfE, YInfE, ZInfE;           
   logic 	XInfM, YInfM, ZInfM;
   logic 	XExpMaxE;  
   logic 	XNormE;
   logic 	FDivBusyE;   
   
   logic 	start;
   logic 	reset;

   logic 	XDenorm;
   logic 	YDenorm;   
   logic [63:0] AS_Result;	
   logic [4:0] 	Flags;   	
   logic 	Denorm;   	
   logic 	done;

   logic         clk;
   logic [63:0]  yexpected;
   logic [63:0]  vectornum, errors;    // bookkeeping variables
   logic [199:0] testvectors[50000:0]; // array of testvectors
   logic [7:0] 	 flags_expected;

   integer 	handle3;
   integer 	desc3;  
   integer 	desc4; 
   
   // instantiate device under test
   unpacking unpacking(.X(op1), .Y(op2), .Z(64'h0), .FOpCtrlE, .FmtE, 
		       .XSgnE, .YSgnE, .ZSgnE, .XExpE, .YExpE, .ZExpE, .XManE, .YManE, .ZManE, 
		       .XNaNE, .YNaNE, .ZNaNE, .XSNaNE, .YSNaNE, .ZSNaNE, .XDenormE, .YDenormE, .ZDenormE, 
		       .XZeroE, .YZeroE, .ZZeroE, .BiasE, .XInfE, .YInfE, .ZInfE, .XExpMaxE, .XNormE);
   fpdiv fdivsqrt (.op1, .op2, .rm(FrmE[1:0]), .op_type(FOpCtrlE[0]),
		   .reset, .clk, .start, .P(FmtE), .OvEn(1'b1), .UnEn(1'b1),
		   .XNaNQ(XNaNE), .YNaNQ(YNaNE), .XInfQ(XInfE), .YInfQ(YInfE), .XZeroQ(XZeroE), .YZeroQ(YZeroE),
		   .FDivBusyE, .done(done), .AS_Result(AS_Result), .Flags(Flags));

   // current fpdivsqrt does not operation on denorms yet
   assign XZeroM = (op1[51:0] == 52'h0);
   assign YZeroM = (op2[51:0] == 52'h0);   
   assign XDenorm = XZeroE & ~XZeroM;
   assign YDenorm = YZeroE & ~YZeroM;
   assign Denorm = XDenorm | YDenorm;   

  // generate clock to sequence tests
  always
    begin
      clk = 1; # 5; clk = 0; # 5;
    end
   
   initial
     begin
	handle3 = $fopen("f64_div_rne.out");
	$readmemh("../testbench/fp/f64_div_rne.tv", testvectors);
	vectornum = 0; errors = 0;
	start = 1'b0;
	// reset
	reset = 1; #27; reset = 0;
     end

   initial
     begin
	desc3 = handle3;
	// Operation (if applicable)
	#0  op_type = 1'b0;
	// Precision (32-bit or 64-bit)
	#0  FmtE = 1'b0;
	// From fctrl logic to dictate operation
	#0  FOpCtrlE = 3'b000;
	// Rounding Mode
	#0  FrmE = 3'b000;
	// Trap masking (n/a for RISC-V)
	#0  OvEn = 1'b0;
	#0  UnEn = 1'b0;
     end

   always @(posedge clk)
     begin
	if (~reset)
	  begin
	     #0; {op1, op2, yexpected, flags_expected} = testvectors[vectornum];
	     #50 start = 1'b1;
	     repeat (2)
	       @(posedge clk);
	     // deassert start after 2 cycles
	     start = 1'b0;	
	     repeat (10)
	       @(posedge clk);
	     $fdisplay(desc3, "%h_%h_%h_%b_%b | %h_%b", op1, op2, AS_Result, Flags, Denorm, yexpected, (AS_Result==yexpected));
	     vectornum = vectornum + 1;
	     if (vectornum == 1)
	       $finish;	     
	     if (testvectors[vectornum] === 200'bx) begin
		$display("%d tests completed", vectornum);
		$finish;
	     end
	  end // if (~reset)
	$display("%d vectors processed", vectornum);
     end // always @ (posedge clk)
   
endmodule // tb



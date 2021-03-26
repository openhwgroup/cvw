// testbench
module tb ();

   reg [63:0]  op1;		
   reg [63:0]  op2;		
   reg [2:0] 	 rm;		
   reg [3:0]	 op_type;	
   reg  	P;   		
   reg 	 OvEn;		
   reg	 UnEn;   	

   wire [63:0]  result;
   wire [4:0]   Flags;   	
   wire 	 Denorm;   	

   reg         clk, tb_clk;
   reg [63:0]  yexpected, yexpected_next;
   reg	 reset;   
   reg [63:0]  vectornum, errors;    // bookkeeping variables
   reg [199:0] testvectors[49999:0]; // array of testvectors
   reg [7:0] 	 flags_expected, flags_expected_next;

   integer 	handle3;
   integer 	desc3;   
   
   // instantiate device under test
   fpuadd_testpipe dut (result, Flags, Denorm, op1, op2, rm, op_type, P, OvEn, UnEn, clk);   

   always     
     begin
	clk = 1;
	tb_clk = 1;
       	#5; 
	clk = 0; 
	#5;
	clk = 1;
	tb_clk = 0;
	#5;
	clk = 0;
	#5;
     end
   
   initial
     begin
	handle3 = $fopen("../../fpuaddcvt/test_vectors/f64_add_rne.txt");
	$readmemh("../../fpuaddcvt/test_vectors/f64_add_rne.tv", testvectors);
	vectornum = 0; errors = 0;
	reset = 1;#10;reset = 0;
	//reset = 1; #30; reset = 0;
     end

   always @(negedge tb_clk)
     begin
	desc3 = handle3;
	#0  op_type = 4'b0000;
	#0  P = 1'b0;
	#0  rm = 3'b000;
	#0  OvEn = 1'b0;
	#0  UnEn = 1'b0;
	#1; {yexpected_next, flags_expected_next} = {yexpected, flags_expected};
	#0; {op1, op2, yexpected, flags_expected} = testvectors[vectornum];
	#5 $fdisplay(desc3, "%h_%h_%h_%b", op1, op2, result, Flags);	
     end

   // check results on rising edge of clk - actual results calculated on
   // negedge
   //
   // skip initial cycle
   always @(posedge tb_clk)
     if (~reset) 
       begin // skip during reset
          #1;
	  if (result !== yexpected) begin  
             $display("Error: inputs = %h %h", op1, op2);
             $display("  outputs = %h (%h expected)", result, yexpected);
             errors = errors + 1;
	  end
	  //else 
	  //begin
          //$display("Good");
	  // end
	  
	  vectornum = vectornum + 1;
	  if (testvectors[vectornum] === 200'bx) 
	    begin 
               $display("%d tests completed with %d errors", 
			vectornum, errors);
		$stop;
	    end	
       end // if (~reset)
   
endmodule // tb



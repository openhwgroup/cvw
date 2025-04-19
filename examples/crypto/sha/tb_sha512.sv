`timescale 1ns/1ps
module stimulus;

   parameter MSG_SIZE = 72; // Go Wally!   

   logic [MSG_SIZE-1:0] message;   
   logic [511:0] hashed;

   logic 	 clk;
   logic [31:0]  errors;
   logic [31:0]  vectornum;
   logic [511:0]  result;
   logic [7:0] 	 op;
   // Size of [583:0] is size of vector in file:  72 + 512 = 584 bits
   logic [583:0] testvectors[511:0];
     
   
   integer 	 handle3;
   integer 	 desc3;
   integer 	 i;  
   integer       j;

   top #(MSG_SIZE, 1024) dut (message, hashed);

   // 1 ns clock
   initial 
     begin	
	clk = 1'b1;
	forever #5 clk = ~clk;
     end

   initial
     begin
        handle3 = $fopen("sha512.out");
        $readmemh("sha512.tv", testvectors);       
        vectornum = 0;
        errors = 0;             
        desc3 = handle3;
     end

   
   // apply test vectors on rising edge of clk
   always @(posedge clk)
     begin
        #1; {message, result} = testvectors[vectornum];
     end  

   // check results on falling edge of clk
  always @(negedge clk)
    begin
       if (result != hashed)
            errors = errors + 1;
        $fdisplay(desc3, "%h %h || %h || %b", 
                 message, hashed, result, (result == hashed));
       vectornum = vectornum + 1;
       if (testvectors[vectornum] === 584'bx) 
         begin 
            $display("%d tests completed with %d errors", 
                     vectornum, errors);
            $finish;
         end
    end

endmodule // stimulus

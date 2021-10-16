module mult_cs #(parameter WIDTH = 8) 
   (a, b, tc, sum, carry);

   input logic [WIDTH-1:0]    a;
   input logic [WIDTH-1:0]    b;
   input logic 		      tc;
   
   output logic [2*WIDTH-1:0] sum, carry;

   // PP array
   logic [2*WIDTH-1:0] 	      pp_array [0:WIDTH-1];
   logic [2*WIDTH-1:0] 	      tmp_sum, tmp_carry;
   logic [2*WIDTH-1:0] 	      a_padded;
   logic [2*WIDTH-1:0] 	      b_padded;
   logic [2*WIDTH-1:0] 	      product;
   
   assign a_padded = a;
   assign b_padded = b;

   always_comb 
     begin 
	logic [2*WIDTH-1:0]  temp_pp_array [0 : WIDTH-1];
	logic [2*WIDTH-1:0]  next_pp_array [0 : WIDTH-1];
	logic [2*WIDTH-1:0]  temp_pp;
	logic [2*WIDTH-1:0]  tmp_pp_carry;
	logic [WIDTH+2:0]    temp_b_padded;
	logic 		     temp_bitgroup;	
	integer 	     bit_pair, pp_count, i;
	
	temp_pp_array[0] = {2*WIDTH{1'b0}};	

	// For each multiplicand
	for (bit_pair=0; bit_pair < WIDTH; bit_pair=bit_pair+1)
	  begin
	     // Shift to the right multiplier
	     temp_b_padded = (b_padded >> (bit_pair));	     	     
	     temp_bitgroup = temp_b_padded[0];

	     // PP generation
	     case (temp_bitgroup)
               1'b0 :
		 temp_pp = {2*WIDTH{1'b0}};
               1'b1 :
		 temp_pp = a_padded;
               default : temp_pp = {2*WIDTH{1'b0}};
	     endcase

	     // Shift to the left via P&H
	     temp_pp = temp_pp << (bit_pair);
	     temp_pp_array[bit_pair] = temp_pp;
	  end 
	
	pp_count = WIDTH;

	// Wallace Tree (I do not think this is really a Wallace tree (misses HA))
	while (pp_count > 2)
	  begin
	     for (i=0 ; i < (pp_count/3) ; i = i+1)
	       begin
		  next_pp_array[i*2] = temp_pp_array[i*3]^temp_pp_array[i*3+1]^temp_pp_array[i*3+2];		  
		  tmp_pp_carry = (temp_pp_array[i*3] & temp_pp_array[i*3+1]) |
				 (temp_pp_array[i*3+1] & temp_pp_array[i*3+2]) |
				 (temp_pp_array[i*3] & temp_pp_array[i*3+2]);
		  next_pp_array[i*2+1] = tmp_pp_carry << 1;
	       end
	     if ((pp_count % 3) > 0)
	       begin
		  for (i=0 ; i < (pp_count % 3) ; i=i+1)
		    next_pp_array[2 * (pp_count/3) + i] = temp_pp_array[3 * (pp_count/3) + i];
	       end
	     for (i=0 ; i < WIDTH ; i=i+1) 
               temp_pp_array[i] = next_pp_array[i];
	     pp_count = pp_count - (pp_count/3);
	  end

	tmp_sum = temp_pp_array[0];

	if (pp_count > 1)
	  tmp_carry = temp_pp_array[1];
	else
	  tmp_carry = {2*WIDTH{1'b0}};
     end 

   assign sum = tmp_sum;
   assign carry = tmp_carry;

endmodule // mult_cs


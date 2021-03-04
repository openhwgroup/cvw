// Ross Thompson
// November 05, 2019
// Oklahoma State University

module function_radix();

   parameter PRELOAD_FILE = "funct_addr.txt";

   integer memory_bank [];
   integer index;

   logic [`XLEN-1:0] pc;
   
   initial begin
     $init_signal_spy("/riscv_mram_tb/dut/pc", "/riscv_mram_tb/function_radix/pc");
   end

   task automatic bin_search_min;
      input integer pc;
      input integer length;
      ref integer   array [];
      output integer minval;

      integer 	     left, right;
      integer 	     mid;

      begin
	 left = 0;
	 right = length;
	 while (left <= right) begin
	    mid = left + ((right - left) / 2);
	    if (array[mid] == pc) begin
	       minval = array[mid];
	       return;
            end
	    if (array[mid] < pc) begin
	      left = mid + 1;
	    end else begin
	      right = mid -1;
	    end
	 end // while (left <= right)
	 // if the element pc is now found, right and left will be equal at this point.
	 // we need to check if pc is less than the array at left or greather.
	 // if it is less than pc, then we select left as the index.
	 // if it is greather we want 1 less than left.
	 if (array[left] < pc) begin
	    minval = array[left];
	    return;	    
	 end else begin
	    minval = array[left-1];
	    return;
	 end
      end
   endtask

   
   // preload
   initial $readmemh(PRELOAD_FILE, memory_bank);

   // we need to count the number of lines in the file so we can set line_count.
   integer fp;
   integer line_count = 0;
   logic [31:0] line;
   initial begin
      fp = $fopen(PRELOAD_FILE, "r");
      // read line by line to count lines
      if (fp) begin
	 while (! $feof(fp)) begin
	    $fscanf(fp, "%h\n", line);
	    line_count = line_count + 1;
	 end
      end else begin
	 $display("Cannot open file %s for reading.", PRELOAD_FILE);
	 $stop;
      end
   end

   always @(pc) begin
      bin_search_min(pc, line_count, memory_bank, index);
      
   end

endmodule // function_radix


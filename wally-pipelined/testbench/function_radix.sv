///////////////////////////////////////////
// datapath.sv
//
// Written: Ross Thompson
// email: ross1728@gmail.com
// Created: November 9, 2019
//
// Purpose: Finds the current function or global assembly label based on PCE.
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

`include "wally-config.vh"

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


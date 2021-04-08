
// Black cell
module black(gout, pout, gin, pin);

   input [1:0] gin, pin;
   output      gout, pout;

   assign pout=pin[1]&pin[0];
   assign gout=gin[1]|(pin[1]&gin[0]);

endmodule // black

// Grey cell
module grey(gout, gin, pin);

   input[1:0] gin;
   input      pin;
   output     gout;

   assign gout=gin[1]|(pin&gin[0]);

endmodule // grey

// reduced Black cell
module rblk(hout, iout, gin, pin);

   input [1:0] gin, pin;
   output      hout, iout;

   assign iout=pin[1]&pin[0];
   assign hout=gin[1]|gin[0];

endmodule // rblk

// reduced Grey cell
module rgry(hout, gin);

   input[1:0] gin;
   output     hout;

   assign hout=gin[1]|gin[0];

endmodule // rgry

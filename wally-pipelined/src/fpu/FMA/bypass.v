/////////////////////////////////////////////////////////////////////////////
//  
// Block Name:	bypass.v
// Author:		David Harris
// Date:		11/2/1995
//
// Block Description:
//   This block contains the bypass muxes which allow fast prerounded
//   bypass to the X and Z inputs of the FMAC
//
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
module bypass(xrf[63:0], zrf[63:0], wbypass[63:0], bypsel[1:0],
			   x[63:0], z[63:0]);
/////////////////////////////////////////////////////////////////////////////

	input     	[63:0]     	xrf;         	// X from register file 
	input      	[63:0]   	zrf;           	// Z  from register file
	input      	[63:0]     	wbypass;     	// Prerounded result for bypass 
	input      	[1:0] 		bypsel;         // Select bypass to X or Z 
	output    	[63:0]      x;           	// Source X
	output    	[63:0]   	z;           	// Source Z

	// If bypass select is asserted, bypass source, else take reg file value

	assign x = bypsel[0] ? wbypass : xrf;
	assign z = bypsel[1] ? wbypass : zrf;

endmodule

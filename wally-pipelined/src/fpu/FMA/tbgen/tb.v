`timescale 1 ns/10 ps
module tb;


 reg 		[63:0]		xrf;
 reg 		[63:0]		y;
 reg 		[63:0]		zrf;
 reg 		[63:0]		ans;
 reg 						rn;
 reg 						rz;
 reg 						rm;
 reg 						rp;
 reg 		[63:0]		earlyres;
 reg 						earlyressel;
 reg 		[1:0]			bypsel;
 reg 						bypplus1;
 reg 						byppostnorm;
 wire 	[63:0]		w;
 wire 	[63:0]		wbypass;
 wire 		 			invalid;
 wire 					overflow;
 wire 					underflow;
 wire 					inexact;

integer fp;
reg nan;

localparam period = 20;  
fmac UUT(.xrf(xrf), .y(y), .zrf(zrf), .rn(rn), .rz(rz), .rp(rp), .rm(rm),
		.earlyres(earlyres), .earlyressel(earlyressel), .bypsel(bypsel), .bypplus1(bypplus1), .byppostnorm(byppostnorm), 
		.w(w), .wbypass(wbypass), .invalid(invalid), .overflow(overflow), .underflow(underflow), .inexact(inexact));


initial 
    begin
    fp = $fopen("/home/kparry/code/FMAC/tbgen/results.dat","w");
    xrf = 64'h400FEFFFFFFDFFFF;
    y = 64'h4500001EFFFFFFFF;
    zrf = 64'h0000000000000000;
    ans = 64'h451FF03DE0FDFFF9;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"0\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'h44223BDB544F0B29;
    ans = 64'h44223BDB544F0B29;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"1\n");
    end
    xrf = 64'hC2EA48415773CAAE;
    y = 64'hF7FFFFFFF0000010;
    zrf = 64'hC3EFFFDFFFFFFFFE;
    ans = 64'h7AFA48414A4FAA0F;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"2\n");
    end
    xrf = 64'h7FF8CDB067A39BAF;
    y = 64'h0000000000000000;
    zrf = 64'h0000000000000000;
    ans = 64'h7FF8CDB067A39BAF;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"3\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'hCFAFEFFEFFFFFFFE;
    zrf = 64'hC0FFFFFFBF7FFFFE;
    ans = 64'hC0FFFFFFBF7FFFFE;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"4\n");
    end
    xrf = 64'h3FC00000000FFDFF;
    y = 64'h0000000000000000;
    zrf = 64'hBCA1570F41BFB2DC;
    ans = 64'hBCA1570F41BFB2DC;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"5\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'hBFDFFFFDFFFFFEFF;
    zrf = 64'h0000000000000000;
    ans = 64'h0000000000000000;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"6\n");
    end
    xrf = 64'h3FDBFFFFFFFFFF7F;
    y = 64'hDE608000000001FF;
    zrf = 64'h43CFED83C17EDBD0;
    ans = 64'hDE4CE000000002F9;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"7\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'h0000000000000000;
    ans = 64'h0000000000000000;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"8\n");
    end
    xrf = 64'hBFDC091B6B9B61DA;
    y = 64'hBF41FFFFFFFFFFDE;
    zrf = 64'h0000000000000001;
    ans = 64'h3F2F8A3ED90ECDDA;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"9\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'hC00FD6C97456B6F8;
    ans = 64'hC00FD6C97456B6F8;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"10\n");
    end
    xrf = 64'hC3E8F36E6B907786;
    y = 64'h3FC5C725C515C2B9;
    zrf = 64'h7FE0000040080000;
    ans = 64'h7FE0000040080000;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"11\n");
    end
    xrf = 64'hC6E000000000BFFF;
    y = 64'h0000000000000000;
    zrf = 64'h0000000000000001;
    ans = 64'h0000000000000001;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"12\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h43400000FFFEFFFF;
    zrf = 64'h47E61D287E42ED93;
    ans = 64'h47E61D287E42ED93;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"13\n");
    end
    xrf = 64'h42BC000000003FFF;
    y = 64'h0000000000000000;
    zrf = 64'hB1E9BC9A428F5884;
    ans = 64'hB1E9BC9A428F5884;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"14\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h402E266600DC8429;
    zrf = 64'h0000000000000001;
    ans = 64'h0000000000000001;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"15\n");
    end
    xrf = 64'h3FE0000000008002;
    y = 64'h7A300001FFFF8000;
    zrf = 64'h151001FFFDFFFFFF;
    ans = 64'h7A20000200000002;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"16\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'h0000000000000001;
    ans = 64'h0000000000000001;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"17\n");
    end
    xrf = 64'h0020000803FFFFFF;
    y = 64'hBFCB4181A9468E24;
    zrf = 64'h000FFFFFFFFFFFFF;
    ans = 64'h00092F9C2BCA0F33;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"18\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'hC00FFFFDFFC00000;
    ans = 64'hC00FFFFDFFC00000;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"19\n");
    end
    xrf = 64'h403FFEFFFFFDFFFF;
    y = 64'h480FFFFFFFFFFBFA;
    zrf = 64'h38059A71C7F5B8A0;
    ans = 64'h485FFEFFFFFDFBF9;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"20\n");
    end
    xrf = 64'h8FB0000BFFFFFFFF;
    y = 64'h0000000000000000;
    zrf = 64'h000FFFFFFFFFFFFF;
    ans = 64'h000FFFFFFFFFFFFF;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"21\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h4010000007FEFFFE;
    zrf = 64'hC05FFFF7F7FFFFFF;
    ans = 64'hC05FFFF7F7FFFFFF;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"22\n");
    end
    xrf = 64'h43DFFFFFFFC01FFF;
    y = 64'h0000000000000000;
    zrf = 64'hC010003FFFFFF7FE;
    ans = 64'hC010003FFFFFF7FE;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"23\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'hC14FFFFFFFFFF77F;
    zrf = 64'h000FFFFFFFFFFFFF;
    ans = 64'h000FFFFFFFFFFFFF;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"24\n");
    end
    xrf = 64'hC80F0000FFFFFFFF;
    y = 64'h80800003FFFFFFF6;
    zrf = 64'h3FEFFFFF00000400;
    ans = 64'h3FEFFFFF00000400;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"25\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'h000FFFFFFFFFFFFF;
    ans = 64'h000FFFFFFFFFFFFF;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"26\n");
    end
    xrf = 64'h3FA000004000FFFF;
    y = 64'hBEBBDADC34FC7443;
    zrf = 64'h000FFFFFFFFFFFFE;
    ans = 64'hBE6BDADCA469A2C3;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"27\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'hBFD00000F7FFFFFF;
    ans = 64'hBFD00000F7FFFFFF;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"28\n");
    end
    xrf = 64'hBFCFFFFFE0000800;
    y = 64'hC349D6DCD4B1B809;
    zrf = 64'h2DB0000101000000;
    ans = 64'h4329D6DCBADAE1AA;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"29\n");
    end
    xrf = 64'h37EF000040000000;
    y = 64'h0000000000000000;
    zrf = 64'h000FFFFFFFFFFFFE;
    ans = 64'h000FFFFFFFFFFFFE;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"30\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h40B1D54BCBAB279F;
    zrf = 64'h0DF0400000000FFF;
    ans = 64'h0DF0400000000FFF;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"31\n");
    end
    xrf = 64'hC1C0000002000007;
    y = 64'h0000000000000000;
    zrf = 64'h7FF0020007FFFFFF;
    ans = 64'h7FF8020007FFFFFF;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"32\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'hFFD00001FFFFEFFF;
    zrf = 64'h000FFFFFFFFFFFFE;
    ans = 64'h000FFFFFFFFFFFFE;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"33\n");
    end
    xrf = 64'hB89FFE0000800000;
    y = 64'hC000000008000010;
    zrf = 64'h40BFFFF000000000;
    ans = 64'h40BFFFF000000000;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"34\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'h000FFFFFFFFFFFFE;
    ans = 64'h000FFFFFFFFFFFFE;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"35\n");
    end
    xrf = 64'h7FFFFFE0000FFFFF;
    y = 64'h403000001EFFFFFF;
    zrf = 64'h0010000000000000;
    ans = 64'h7FFFFFE0000FFFFF;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"36\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'hC1E00000003FFF00;
    ans = 64'hC1E00000003FFF00;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"37\n");
    end
    xrf = 64'h41DF6C9ACFECE989;
    y = 64'hDDD000007FF80000;
    zrf = 64'h3811FFFFBFFFFFFF;
    ans = 64'hDFBF6C9BCB4209BB;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"38\n");
    end
    xrf = 64'hBFE000007F7FFFFE;
    y = 64'h0000000000000000;
    zrf = 64'h0010000000000000;
    ans = 64'h0010000000000000;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"39\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h7FDFFFFFF7FFF7FF;
    zrf = 64'hC0ED55FCCA2B50EB;
    ans = 64'hC0ED55FCCA2B50EB;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"40\n");
    end
    xrf = 64'h3D20800000000007;
    y = 64'h0000000000000000;
    zrf = 64'hC7FB24E113B21D95;
    ans = 64'hC7FB24E113B21D95;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"41\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h38F53256F1FD8142;
    zrf = 64'h0010000000000000;
    ans = 64'h0010000000000000;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"42\n");
    end
    xrf = 64'hC7F01FFFFFFFDFFF;
    y = 64'hC1ABF0533F99CA52;
    zrf = 64'hC7AFFFFFFFBFFFBF;
    ans = 64'h49AC2833E5F8C604;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"43\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'h0010000000000000;
    ans = 64'h0010000000000000;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"44\n");
    end
    xrf = 64'hC3C000800000001E;
    y = 64'hC00000004000FFFE;
    zrf = 64'h0010000000000001;
    ans = 64'h43D0008040030024;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"45\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'h38069508D6E94770;
    ans = 64'h38069508D6E94770;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"46\n");
    end
    xrf = 64'h47ED0C441E79F5B4;
    y = 64'h3FEB3443F10FF3AF;
    zrf = 64'h381314487C5CB930;
    ans = 64'h47E8B1CB14E9E948;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"47\n");
    end
    xrf = 64'hE27F800000001FFF;
    y = 64'h0000000000000000;
    zrf = 64'h0010000000000001;
    ans = 64'h0010000000000001;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"48\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h3FDF58F9EF4BA87A;
    zrf = 64'h47E0001FFFFFC000;
    ans = 64'h47E0001FFFFFC000;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"49\n");
    end
    xrf = 64'h405FFFFFFFFF7DFF;
    y = 64'h0000000000000000;
    zrf = 64'hB80FFFFFDFFF7FFF;
    ans = 64'hB80FFFFFDFFF7FFF;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"50\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h4CA00000000020FF;
    zrf = 64'h0010000000000001;
    ans = 64'h0010000000000001;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"51\n");
    end
    xrf = 64'h4F7FFFFFFFFFE008;
    y = 64'hBD9FFBF7FFFFFFFE;
    zrf = 64'h3CA9EF3DF0B18874;
    ans = 64'hCD2FFBF7FFFFE00A;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"52\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'h0010000000000001;
    ans = 64'h0010000000000001;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"53\n");
    end
    xrf = 64'h43D001FFFFFEFFFE;
    y = 64'hB3B001FFFC000000;
    zrf = 64'h001FFFFFFFFFFFFF;
    ans = 64'hB79004003BFE7FDE;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"54\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'hBFE42B7098B68BA8;
    ans = 64'hBFE42B7098B68BA8;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"55\n");
    end
    xrf = 64'h985FFFFFBFFFFFF7;
    y = 64'h3FBBEEC107717254;
    zrf = 64'hBFD0100000001FFF;
    ans = 64'hBFD0100000001FFF;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"56\n");
    end
    xrf = 64'hB81FFFFFFFFFE000;
    y = 64'h0000000000000000;
    zrf = 64'h001FFFFFFFFFFFFF;
    ans = 64'h001FFFFFFFFFFFFF;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"57\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h2BDD9A85D2E4683C;
    zrf = 64'hFFDFFFFFE0000004;
    ans = 64'hFFDFFFFFE0000004;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"58\n");
    end
    xrf = 64'h380FFFFFFF8001FF;
    y = 64'h0000000000000000;
    zrf = 64'h1B5B3B4837FBA184;
    ans = 64'h1B5B3B4837FBA184;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"59\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h43DF7FFFFFFFFFC0;
    zrf = 64'h001FFFFFFFFFFFFF;
    ans = 64'h001FFFFFFFFFFFFF;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"60\n");
    end
    xrf = 64'hB7E49210AC9E1B87;
    y = 64'hBF3FFFFFFE001FFF;
    zrf = 64'hB23FFFFCFFFFFFFE;
    ans = 64'h37349210AB550F0E;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"61\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'h001FFFFFFFFFFFFF;
    ans = 64'h001FFFFFFFFFFFFF;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"62\n");
    end
    xrf = 64'h403251D97A5E1D0C;
    y = 64'h404705F7FFDBD87F;
    zrf = 64'h001FFFFFFFFFFFFE;
    ans = 64'h408A5C7E285F0A79;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"63\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'hFFEFFFFFFFFFF7EE;
    ans = 64'hFFEFFFFFFFFFF7EE;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"64\n");
    end
    xrf = 64'h402017FFFFFFFFFF;
    y = 64'h3831000FFFFFFFFF;
    zrf = 64'h38159741BD9D38BC;
    ans = 64'h3861C64A25ECE9C4;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"65\n");
    end
    xrf = 64'h3FBFEFFFFFFFFFF0;
    y = 64'h0000000000000000;
    zrf = 64'h001FFFFFFFFFFFFE;
    ans = 64'h001FFFFFFFFFFFFE;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"66\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h43226FDD109DA24F;
    zrf = 64'hD9BFFC01FFFFFFFF;
    ans = 64'hD9BFFC01FFFFFFFF;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"67\n");
    end
    xrf = 64'h5590001EFFFFFFFF;
    y = 64'h0000000000000000;
    zrf = 64'h0FB4EBC00336E272;
    ans = 64'h0FB4EBC00336E272;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"68\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h3FB2B6972F81C429;
    zrf = 64'h001FFFFFFFFFFFFE;
    ans = 64'h001FFFFFFFFFFFFE;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"69\n");
    end
    xrf = 64'hB6EFFFFFFFFFFDDF;
    y = 64'h7FD100000000003E;
    zrf = 64'hC070000000003FF6;
    ans = 64'hF6D0FFFFFFFFFF1C;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"70\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'h001FFFFFFFFFFFFE;
    ans = 64'h001FFFFFFFFFFFFE;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"71\n");
    end
    xrf = 64'h418023FFFFFFFFFF;
    y = 64'h41D077FFFFFFFFFE;
    zrf = 64'h3CA0000000000000;
    ans = 64'h43609D0DFFFFFFFD;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"72\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'h3D20000020100000;
    ans = 64'h3D20000020100000;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"73\n");
    end
    xrf = 64'h3FDFFFFFFFFFC03F;
    y = 64'hC1EFFFFFFFFFFC3F;
    zrf = 64'hC00000007FFEFFFE;
    ans = 64'hC1E00000003FDE41;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"74\n");
    end
    xrf = 64'h41C0000000000002;
    y = 64'h0000000000000000;
    zrf = 64'h3CA0000000000000;
    ans = 64'h3CA0000000000000;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"75\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h403978692A8E71A0;
    zrf = 64'hC05EA17BB565F286;
    ans = 64'hC05EA17BB565F286;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"76\n");
    end
    xrf = 64'h47E70A2E50D58207;
    y = 64'h0000000000000000;
    zrf = 64'h3C13ABADB322843E;
    ans = 64'h3C13ABADB322843E;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"77\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'hBE8FFFFC00800000;
    zrf = 64'h3CA0000000000000;
    ans = 64'h3CA0000000000000;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"78\n");
    end
    xrf = 64'hBFF000101FFFFFFE;
    y = 64'hC00BFFFFFFFFFF7F;
    zrf = 64'h3F1BAA5CC75710E9;
    ans = 64'h400C00538CB98E2A;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"79\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'h3CA0000000000000;
    ans = 64'h3CA0000000000000;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"80\n");
    end
    xrf = 64'hBE303FFFFF7FFFFF;
    y = 64'hC7E0100FFFFFFFFE;
    zrf = 64'h3CA0000000000001;
    ans = 64'h462050503F7F7F7D;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"81\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'hC1D007FFFFFBFFFE;
    ans = 64'hC1D007FFFFFBFFFE;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"82\n");
    end
    xrf = 64'h46D0400FFFFFFFFE;
    y = 64'hC0B6AB0CA0885B97;
    zrf = 64'h3FD0000080000000;
    ans = 64'hC79705CF7E171D8B;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"83\n");
    end
    xrf = 64'hCFB00000080FFFFF;
    y = 64'h0000000000000000;
    zrf = 64'h3CA0000000000001;
    ans = 64'h3CA0000000000001;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"84\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h3FC000000000403F;
    zrf = 64'hC1F0000000000107;
    ans = 64'hC1F0000000000107;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"85\n");
    end
    xrf = 64'h8160000200020000;
    y = 64'h0000000000000000;
    zrf = 64'hC3C00000002FFFFE;
    ans = 64'hC3C00000002FFFFE;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"86\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h43401000000001FF;
    zrf = 64'h3CA0000000000001;
    ans = 64'h3CA0000000000001;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"87\n");
    end
    xrf = 64'h4289103C0B784F2D;
    y = 64'h4030000001FFFFFE;
    zrf = 64'hC7F61FD7734A9B57;
    ans = 64'hC7F61FD7734A9B57;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"88\n");
    end
    xrf = 64'h0000000000000000;
    y = 64'h0000000000000000;
    zrf = 64'h3CA0000000000001;
    ans = 64'h3CA0000000000001;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"89\n");
    end
    xrf = 64'h880E1FFFFFFFFFFE;
    y = 64'h8CDFFFFF7FF7FFFF;
    zrf = 64'h3CAFFFFFFFFFFFFF;
    ans = 64'h3CAFFFFFFFFFFFFF;
    rn = 1;
    rz = 0;
    rm = 0;
    rp = 0;
    earlyres = 64'b0;
    earlyressel = 0;
    bypsel= 2'b0;
    bypplus1 = 0;
    byppostnorm = 0;
#10
    // IEEE 754-2008 section 6.3 states: "When ether an input or result is NaN, this
    //                                     standard does not interpret the sign of a NaN."
	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||
	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||
	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||
	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );
	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin
		$fwrite(fp, "%h %h %h %h %h  Wrong ",xrf,y, zrf, w, ans);
		if(w == 64'h8000000000000000) $fwrite(fp, "w=-zero ");
		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, "xdenorm ");
		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, "ydenorm ");
		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, "zdenorm ");
		if(invalid != 0) $fwrite(fp, "invld ");
		if(overflow != 0) $fwrite(fp, "ovrflw ");
		if(underflow != 0) $fwrite(fp, "unflw ");
		if(w == 64'hFFF0000000000000) $fwrite(fp, "w=-inf ");
		if(w == 64'h7FF0000000000000) $fwrite(fp, "w=+inf ");
		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, "w=sigNaN ");
		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, "w=qutNaN ");
		if(ans == 64'hFFF0000000000000) $fwrite(fp, "ans=-inf ");
		if(ans == 64'h7FF0000000000000) $fwrite(fp, "ans=+inf ");
		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, "ans=sigNaN ");
		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, "ans=qutNaN ");
    	$fwrite(fp,"90\n");
    end
	$stop;
	end
endmodule
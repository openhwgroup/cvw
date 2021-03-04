#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void main() {
	FILE *fp, *fq, *fr;
	int cnt=0;
	char *ln;
	size_t nbytes = 80;

	ln = (char *)malloc(nbytes + 1);

	// fp = fopen("tb.dat","r");
	fp = fopen("testFloat","r");
	fq = fopen("tb.v","a");
	system("cp tbhead.v tb.v");
	int k=0;
	for(k=0; k<91 && !feof(fp); k++) {
		//3FDBFFFFFFFFFF7F DE608000000001FF 43CFED83C17EDBD0 DE4CE000000002F9 01
		// b68ffff8000000ff_3f9080000007ffff_b6307ffbe0080080_00001
        char ch;
		int i,j;
		char *ln;
		char xrf[17];
		char y[17];
		char zrf[17];
		char ans[81];
		char flags[3];
		int rn,rz,rm,rp;
		{
  //my_string = (char *) malloc (nbytes + 1);
  //bytes_read = getline (&my_string, &nbytes, stdin);
			if(getline(&ln,&nbytes,fp) < 0) break;
			//fprintf(stderr,"%s\n", ln);

			strncpy(xrf,   ln,     16); xrf[16]=0;
			strncpy(y,    &ln[17], 16); y[16]=0;
			strncpy(zrf,  &ln[34], 16); zrf[16]=0;
			// fprintf(stdout,"[%s]\n[%s]\n", ln,zrf);
			strncpy(ans,  &ln[51], 16); ans[16]=0;
			strncpy(flags,&ln[68],2);   flags[2]=0;
		
			// fprintf(stdout,"[%s]\n[%s]\n", ln,zrf);
			fprintf(fq,"    xrf = 64'h%s;\n",xrf); 
			fprintf(fq,"    y = 64'h%s;\n",y); 
			fprintf(fq,"    zrf = 64'h%s;\n",zrf);
			fprintf(fq,"    ans = 64'h%s;\n", ans);
			// fprintf(fq,"    flags = 5'h%s;\n", flags);
		}

		{
			//rn=1; rz=0; rm=0; rp=0;
			fprintf(fq,"    rn = %d;\n",1);
			fprintf(fq,"    rz = %d;\n", 0);
			fprintf(fq,"    rm = %d;\n", 0);
			fprintf(fq,"    rp = %d;\n", 0);
		}
		{
			fprintf(fq,"    earlyres = 64'b0;\n");
			fprintf(fq,"    earlyressel = 0;\n");
		}		
		{

			fprintf(fq,"    bypsel= 2'b0;\n"); //, bysel);
			fprintf(fq,"    bypplus1 = 0;\n"); //, byp1);
			fprintf(fq,"    byppostnorm = 0;\n"); //, bypnorm);
		}
		fprintf(fq,"#10\n");
	// IEEE 754-2008 section 6.3 states "When ether an input or result is NaN, this standard does not interpret the sign of a NaN."
		//fprintf(fq,"	$fwrite(fp, \"%%h %%h %%h %%h \",xrf,y,w, ans);\n");	
		fprintf(fq,"    // IEEE 754-2008 section 6.3 states: \"When ether an input or result is NaN, this\n");
		fprintf(fq,"    //                                     standard does not interpret the sign of a NaN.\"\n");
 		fprintf(fq,"	nan = (w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000)  ||\n");
 		fprintf(fq,"	      (w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) ||\n");
 		fprintf(fq,"	      (w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) ||\n");
 		fprintf(fq,"	      (w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff );\n");
		// fprintf(fq,"    if(!(~(|xrf[62:52]) && |xrf[51:0] || ~(|y[62:52]) && |y[51:0])) begin\n"); 
																						// not looknig at negative zero results right now
		//fprintf(fq,"	  if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) && !(w == 64'h8000000000000000 && ans == 64'b0)) begin\n"); 
		fprintf(fq,"	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin\n"); 
		fprintf(fq,"		$fwrite(fp, \"%%h %%h %%h %%h %%h  Wrong \",xrf,y, zrf, w, ans);\n");
 		fprintf(fq,"		if(w == 64'h8000000000000000) $fwrite(fp, \"w=-zero \");\n");
 		fprintf(fq,"		if(~(|xrf[62:52]) && |xrf[51:0]) $fwrite(fp, \"xdenorm \");\n");
 		fprintf(fq,"		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, \"ydenorm \");\n");
 		fprintf(fq,"		if(~(|zrf[62:52]) && |zrf[51:0]) $fwrite(fp, \"zdenorm \");\n");
  		fprintf(fq,"		if(invalid != 0) $fwrite(fp, \"invld \");\n");
 		fprintf(fq,"		if(overflow != 0) $fwrite(fp, \"ovrflw \");\n");
 		fprintf(fq,"		if(underflow != 0) $fwrite(fp, \"unflw \");\n");
 		fprintf(fq,"		if(w == 64'hFFF0000000000000) $fwrite(fp, \"w=-inf \");\n");
 		fprintf(fq,"		if(w == 64'h7FF0000000000000) $fwrite(fp, \"w=+inf \");\n");
 		fprintf(fq,"		if(w >  64'h7FF0000000000000 && w <  64'h7FF8000000000000 ) $fwrite(fp, \"w=sigNaN \");\n");
 		fprintf(fq,"		if(w >  64'hFFF8000000000000 && w <  64'hFFF8000000000000 ) $fwrite(fp, \"w=sigNaN \");\n");
 		fprintf(fq,"		if(w >= 64'h7FF8000000000000 && w <= 64'h7FFfffffffffffff ) $fwrite(fp, \"w=qutNaN \");\n");
 		fprintf(fq,"		if(w >= 64'hFFF8000000000000 && w <= 64'hFFFfffffffffffff ) $fwrite(fp, \"w=qutNaN \");\n");

 		fprintf(fq,"		if(ans == 64'hFFF0000000000000) $fwrite(fp, \"ans=-inf \");\n");
 		fprintf(fq,"		if(ans == 64'h7FF0000000000000) $fwrite(fp, \"ans=+inf \");\n");
		fprintf(fq,"		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, \"ans=sigNaN \");\n");
 		fprintf(fq,"		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, \"ans=sigNaN \");\n");
 		fprintf(fq,"		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, \"ans=qutNaN \");\n");
 		fprintf(fq,"		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, \"ans=qutNaN \");\n");
		fprintf(fq,"    	$fwrite(fp,\"%d\\n\");\n",cnt);
		if(cnt == 358)fprintf(fq,"    	$stop;\n");
		// fprintf(fq,"    end\n");
		fprintf(fq,"    end\n");
		cnt++;

		//if(cnt > 100) break;
		fflush(fq);
	}

	fprintf(fq, "\t$stop;\n\tend\nendmodule");
	fclose(fq);
	fclose(fp);
}


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
	long k=0L;
	for(; !feof(fp); k++) {
		//3FDBFFFFFFFFFF7F DE608000000001FF 43CFED83C17EDBD0 DE4CE000000002F9 01
		// b68ffff8000000ff_3f9080000007ffff_b6307ffbe0080080_00001
                char ch;
		int i,j,n;
		char x[17];
		char y[17];
		char z[17];
		char ans[81];
		char flags[3];
		int rn,rz,rm,rp;
		long stop = 5723787;
		int debug = 1;
		//my_string = (char *) malloc (nbytes + 1);
		//bytes_read = getline (&my_string, &nbytes, stdin);
	

		for(n=0; n < 2013; n++) {//613 for 10000
			if(getline(&ln,&nbytes,fp) < 0 || feof(fp)) break;
			if(k == stop && debug == 1) break;
			k++;
		}
		//fprintf(stderr,"%s\n", ln);

		if(!feof(fp)) {

			strncpy(x,   ln,     16); x[16]=0;
			strncpy(y,    &ln[17], 16); y[16]=0;
			strncpy(z,  &ln[34], 16); z[16]=0;
			// fprintf(stdout,"[%s]\n[%s]\n", ln,z);
			strncpy(ans,  &ln[51], 16); ans[16]=0;
			strncpy(flags,&ln[68],2);   flags[2]=0;
		
			// fprintf(stdout,"[%s]\n[%s]\n", ln,z);
			fprintf(fq,"    x = 64'h%s;\n",x); 
			fprintf(fq,"    y = 64'h%s;\n",y); 
			fprintf(fq,"    z = 64'h%s;\n",z);
			fprintf(fq,"    ans = 64'h%s;\n", ans);
			// fprintf(fq,"    flags = 5'h%s;\n", flags);
		

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
			//fprintf(fq,"	$fwrite(fp, \"%%h %%h %%h %%h \",x,y,w, ans);\n");	
			fprintf(fq,"    // IEEE 754-2008 section 6.3 states: \"When ether an input or result is NaN, this\n");
			fprintf(fq,"    //                                     standard does not interpret the sign of a NaN.\"\n");
			fprintf(fq,"	wnan = &w[62:52] && |w[51:0]; \n");
			fprintf(fq,"	xnan = &x[62:52] && |x[51:0]; \n");
			fprintf(fq,"	ynan = &y[62:52] && |y[51:0]; \n");
			fprintf(fq,"	znan = &z[62:52] && |z[51:0]; \n");
			fprintf(fq,"	ansnan = &ans[62:52] && |ans[51:0]; \n");
			fprintf(fq,"	xnorm = ~(|x[62:52]) && |x[51:0] ? {x[50:0], 1'b0} : x; \n");
			fprintf(fq,"	ynorm = ~(|y[62:52]) && |y[51:0] ? {y[50:0], 1'b0} : y;\n");
			fprintf(fq,"	s = ({54'b1,xnorm} + (bypsel  && bypplus1))  *  {54'b1,ynorm}; \n");
			// fprintf(fq,"    if(!(~(|x[62:52]) && |x[51:0] || ~(|y[62:52]) && |y[51:0])) begin\n"); 
																							// not looknig at negative zero results right now
			//fprintf(fq,"	  if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) && !(w == 64'h8000000000000000 && ans == 64'b0)) begin\n"); 
			// fprintf(fq,"	if( (nan && (w[62:0] != ans[62:0])) || (!nan && (w != ans)) ) begin\n"); 
			fprintf(fq,"	if((!wnan && (w != ans)) || (wnan && ansnan && ~(((xnan && (w[62:0] == {x[62:52],1'b1,x[50:0]})) || (ynan && (w[62:0] == {y[62:52],1'b1,y[50:0]}))  || (znan && (w[62:0] == {z[62:52],1'b1,z[50:0]})) || (w[62:0] == ans[62:0])) ))) begin\n"); 
			fprintf(fq,"		$fwrite(fp, \"%%h %%h %%h %%h %%h  Wrong \",x,y, z, w, ans);\n");
			//fprintf(fq,"		$fwrite(fp, \"%%h \",s);\n");
			fprintf(fq,"		if(w == 64'h8000000000000000) $fwrite(fp, \"w=-zero \");\n");
			fprintf(fq,"		if(~(|x[62:52]) && |x[51:0]) $fwrite(fp, \"xdenorm \");\n");
			fprintf(fq,"		if(~(|y[62:52]) && |y[51:0]) $fwrite(fp, \"ydenorm \");\n");
			fprintf(fq,"		if(~(|z[62:52]) && |z[51:0]) $fwrite(fp, \"zdenorm \");\n");
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
			fprintf(fq,"    	$fwrite(fp,\"%ld\\n\");\n",k);
			//fprintf(fq,"    	$stop;\n");
			// fprintf(fq,"    end\n");
			fprintf(fq,"    end\n");
			cnt++;

			//if(cnt > 100) break;
			fflush(fq);
		} // if(!feof(fp))
		if(k == stop && debug == 1) break;
	} // for(k)

	fprintf(fq, "\t$stop;\n\tend\nendmodule");
	fclose(fq);
	fclose(fp);
	fprintf(stdout,"cnt = %d\n",cnt);
}


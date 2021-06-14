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
		char FInput1E[17];
		char FInput2E[17];
		char FInput3E[17];
		char ans[81];
		char flags[3];
		int FrmE;
		long stop = 556555;
		int debug = 0;
		int bits = 32;
		//my_string = (char *) malloc (nbytes + 1);
		//bytes_read = getline (&my_string, &nbytes, stdin);
	

		for(n=0; n < 1000; n++) {//613 for 10000
			if(getline(&ln,&nbytes,fp) < 0 || feof(fp)) break;
			if(k == stop && debug == 1) break;
			k++;
		}
		//fprintf(stderr,"%s\n", ln);

		if(!feof(fp)) {

			strncpy(FInput1E,   ln,     bits/4); FInput1E[bits/4]=0;
			strncpy(FInput2E,    &ln[(bits/4)+1], bits/4); FInput2E[bits/4]=0;
			strncpy(FInput3E,  &ln[((bits/4)+1)*2], bits/4); FInput3E[bits/4]=0;
			// fprintf(stdout,"[%s]\n[%s]\n", ln,FInput3E);
			strncpy(ans,  &ln[((bits/4)+1)*3], bits/4); ans[bits/4]=0;
			strncpy(flags,&ln[((bits/4)+1)*4], 2);   flags[2]=0;
		
			// fprintf(stdout,"[%s]\n[%s]\n", ln,FInput3E);
			if (bits == 32){
				fprintf(fq,"    FInput1E = 64'h%s00000000;\n",FInput1E); 
				fprintf(fq,"    FInput2E = 64'h%s00000000;\n",FInput2E); 
				fprintf(fq,"    FInput3E = 64'h%s00000000;\n",FInput3E);
				fprintf(fq,"    ans = 64'h%s00000000;\n", ans);}
			else{
				fprintf(fq,"    FInput1E = 64'h%s;\n",FInput1E); 
				fprintf(fq,"    FInput2E = 64'h%s;\n",FInput2E); 
				fprintf(fq,"    FInput3E = 64'h%s;\n",FInput3E);
				fprintf(fq,"    ans = 64'h%s;\n", ans);}
			fprintf(fq,"    flags = 5'h%s;\n", flags);
		

			fprintf(fq,"#10\n");
			if (bits == 32){
// IEEE 754-2008 section 6.3 states "When ether an input or result is NaN, this standard does not interpret the sign of a NaN."
			//fprintf(fq,"	$fwrite(fp, \"%%h %%h %%h %%h \",FInput1E,FInput2E,FmaResultM, ans);\n");	
			fprintf(fq,"    // IEEE 754-2008 section 6.3 states: \"When ether an input or result is NaN, this\n");
			fprintf(fq,"    //                                     standard does not interpret the sign of a NaN.\"\n");
			fprintf(fq,"	wnan = &FmaResultM[62:55] && |FmaResultM[54:32]; \n");
			fprintf(fq,"	xnan = &FInput1E[62:55] && |FInput1E[54:32]; \n");
			fprintf(fq,"	ynan = &FInput2E[62:55] && |FInput2E[54:32]; \n");
			fprintf(fq,"	znan = &FInput3E[62:55] && |FInput3E[54:32]; \n");
			fprintf(fq,"	ansnan = &ans[62:55] && |ans[54:32]; \n");
			fprintf(fq,"	xnorm = ~(|FInput1E[62:55]) && |FInput1E[54:32] ? {FInput1E[50:0], 1'b0} : FInput1E; \n");
			fprintf(fq,"	ynorm = ~(|FInput2E[62:55]) && |FInput2E[54:32] ? {FInput2E[50:0], 1'b0} : FInput2E;\n");
			// fprintf(fq,"	s = ({54'b1,xnorm} + (bypsel  && bypplus1))  *  {54'b1,ynorm}; \n");
			// fprintf(fq,"    if(!(~(|FInput1E[62:55]) && |FInput1E[54:32] || ~(|FInput2E[62:55]) && |FInput2E[54:32])) begin\n"); 
																							// not looknig at negative zero results right now
			//fprintf(fq,"	  if( (nan && (FmaResultM[62:0] != ans[62:0])) || (!nan && (FmaResultM != ans)) && !(FmaResultM == 64'h8000000000000000 && ans == 64'b0)) begin\n"); 
			// fprintf(fq,"	if( (nan && (FmaResultM[62:0] != ans[62:0])) || (!nan && (FmaResultM != ans)) ) begin\n"); 
			fprintf(fq,"	if(FmaFlagsM != flags || (!wnan && (FmaResultM != ans)) || (wnan && ansnan && ~(((xnan && (FmaResultM[62:0] == {FInput1E[62:55],1'b1,FInput1E[53:0]})) || (ynan && (FmaResultM[62:0] == {FInput2E[62:55],1'b1,FInput2E[53:0]}))  || (znan && (FmaResultM[62:0] == {FInput3E[62:55],1'b1,FInput3E[53:0]})) || (FmaResultM[62:0] == ans[62:0])) ))) begin\n"); 
			fprintf(fq,"		$fwrite(fp, \"%%h %%h %%h %%h %%h  Wrong \",FInput1E,FInput2E, FInput3E, FmaResultM, ans);\n");
			//fprintf(fq,"		$fwrite(fp, \"%%h \",s);\n");
			// fprintf(fq,"		$fwrite(fp, \"FmaResultM=%%d \",$signed(aligncntE));\n");
			fprintf(fq,"		if(FmaResultM == 64'h8000000000000000) $fwrite(fp, \"FmaResultM=-zero \");\n");
			fprintf(fq,"		if(~(|FInput1E[62:55]) && |FInput1E[54:32]) $fwrite(fp, \"xdenorm \");\n");
			fprintf(fq,"		if(~(|FInput2E[62:55]) && |FInput2E[54:32]) $fwrite(fp, \"ydenorm \");\n");
			fprintf(fq,"		if(~(|FInput3E[62:55]) && |FInput3E[54:32]) $fwrite(fp, \"zdenorm \");\n");
			fprintf(fq,"		if(FmaFlagsM[4] != 0) $fwrite(fp, \"invld \");\n");
			fprintf(fq,"		if(FmaFlagsM[2] != 0) $fwrite(fp, \"ovrflw \");\n");
			fprintf(fq,"		if(FmaFlagsM[1] != 0) $fwrite(fp, \"unflw \");\n");
			fprintf(fq,"		if(FmaResultM == 64'hFF80000000000000) $fwrite(fp, \"FmaResultM=-inf \");\n");
			fprintf(fq,"		if(FmaResultM == 64'h7F80000000000000) $fwrite(fp, \"FmaResultM=+inf \");\n");
			fprintf(fq,"		if(&FmaResultM[62:55] && |FmaResultM[54:32] && ~FmaResultM[54]) $fwrite(fp, \"FmaResultM=sigNaN \");\n");
			fprintf(fq,"		if(&FmaResultM[62:55] && |FmaResultM[54:32] && FmaResultM[54] ) $fwrite(fp, \"FmaResultM=qutNaN \");\n");

			fprintf(fq,"		if(ans == 64'hFF80000000000000) $fwrite(fp, \"ans=-inf \");\n");
			fprintf(fq,"		if(ans == 64'h7F80000000000000) $fwrite(fp, \"ans=+inf \");\n");
			fprintf(fq,"		if(&ans[62:55] && |ans[54:32] && ~ans[54] ) $fwrite(fp, \"ans=sigNaN \");\n");
			fprintf(fq,"		if(&ans[62:55] && |ans[54:32] && ans[54]) $fwrite(fp, \"ans=qutNaN \");\n");
			}//end if bits == 32
			else{
			// IEEE 754-2008 section 6.3 states "When ether an input or result is NaN, this standard does not interpret the sign of a NaN."
			//fprintf(fq,"	$fwrite(fp, \"%%h %%h %%h %%h \",FInput1E,FInput2E,FmaResultM, ans);\n");	
			fprintf(fq,"    // IEEE 754-2008 section 6.3 states: \"When ether an input or result is NaN, this\n");
			fprintf(fq,"    //                                     standard does not interpret the sign of a NaN.\"\n");
			fprintf(fq,"	wnan = &FmaResultM[62:52] && |FmaResultM[51:0]; \n");
			fprintf(fq,"	xnan = &FInput1E[62:52] && |FInput1E[51:0]; \n");
			fprintf(fq,"	ynan = &FInput2E[62:52] && |FInput2E[51:0]; \n");
			fprintf(fq,"	znan = &FInput3E[62:52] && |FInput3E[51:0]; \n");
			fprintf(fq,"	ansnan = &ans[62:52] && |ans[51:0]; \n");
			fprintf(fq,"	xnorm = ~(|FInput1E[62:52]) && |FInput1E[51:0] ? {FInput1E[50:0], 1'b0} : FInput1E; \n");
			fprintf(fq,"	ynorm = ~(|FInput2E[62:52]) && |FInput2E[51:0] ? {FInput2E[50:0], 1'b0} : FInput2E;\n");
			// fprintf(fq,"	s = ({54'b1,xnorm} + (bypsel  && bypplus1))  *  {54'b1,ynorm}; \n");
			// fprintf(fq,"    if(!(~(|FInput1E[62:52]) && |FInput1E[51:0] || ~(|FInput2E[62:52]) && |FInput2E[51:0])) begin\n"); 
																							// not looknig at negative zero results right now
			//fprintf(fq,"	  if( (nan && (FmaResultM[62:0] != ans[62:0])) || (!nan && (FmaResultM != ans)) && !(FmaResultM == 64'h8000000000000000 && ans == 64'b0)) begin\n"); 
			// fprintf(fq,"	if( (nan && (FmaResultM[62:0] != ans[62:0])) || (!nan && (FmaResultM != ans)) ) begin\n"); 
			fprintf(fq,"	if((!wnan && (FmaResultM != ans)) || (wnan && ansnan && ~(((xnan && (FmaResultM[62:0] == {FInput1E[62:52],1'b1,FInput1E[50:0]})) || (ynan && (FmaResultM[62:0] == {FInput2E[62:52],1'b1,FInput2E[50:0]}))  || (znan && (FmaResultM[62:0] == {FInput3E[62:52],1'b1,FInput3E[50:0]})) || (FmaResultM[62:0] == ans[62:0])) ))) begin\n"); 
			fprintf(fq,"		$fwrite(fp, \"%%h %%h %%h %%h %%h  Wrong \",FInput1E,FInput2E, FInput3E, FmaResultM, ans);\n");
			//fprintf(fq,"		$fwrite(fp, \"%%h \",s);\n");
			fprintf(fq,"		$fwrite(fp, \"FmaResultM=%%d \",$signed(aligncntE));\n");
			fprintf(fq,"		if(FmaResultM == 64'h8000000000000000) $fwrite(fp, \"FmaResultM=-zero \");\n");
			fprintf(fq,"		if(~(|FInput1E[62:52]) && |FInput1E[51:0]) $fwrite(fp, \"xdenorm \");\n");
			fprintf(fq,"		if(~(|FInput2E[62:52]) && |FInput2E[51:0]) $fwrite(fp, \"ydenorm \");\n");
			fprintf(fq,"		if(~(|FInput3E[62:52]) && |FInput3E[51:0]) $fwrite(fp, \"zdenorm \");\n");
			fprintf(fq,"		if(FmaFlagsM[4] != 0) $fwrite(fp, \"invld \");\n");
			fprintf(fq,"		if(FmaFlagsM[2] != 0) $fwrite(fp, \"ovrflw \");\n");
			fprintf(fq,"		if(FmaFlagsM[1] != 0) $fwrite(fp, \"unflw \");\n");
			fprintf(fq,"		if(FmaResultM == 64'hFFF0000000000000) $fwrite(fp, \"FmaResultM=-inf \");\n");
			fprintf(fq,"		if(FmaResultM == 64'h7FF0000000000000) $fwrite(fp, \"FmaResultM=+inf \");\n");
			fprintf(fq,"		if(FmaResultM >  64'h7FF0000000000000 && FmaResultM <  64'h7FF8000000000000 ) $fwrite(fp, \"FmaResultM=sigNaN \");\n");
			fprintf(fq,"		if(FmaResultM >  64'hFFF8000000000000 && FmaResultM <  64'hFFF8000000000000 ) $fwrite(fp, \"FmaResultM=sigNaN \");\n");
			fprintf(fq,"		if(FmaResultM >= 64'h7FF8000000000000 && FmaResultM <= 64'h7FFfffffffffffff ) $fwrite(fp, \"FmaResultM=qutNaN \");\n");
			fprintf(fq,"		if(FmaResultM >= 64'hFFF8000000000000 && FmaResultM <= 64'hFFFfffffffffffff ) $fwrite(fp, \"FmaResultM=qutNaN \");\n");

			fprintf(fq,"		if(ans == 64'hFFF0000000000000) $fwrite(fp, \"ans=-inf \");\n");
			fprintf(fq,"		if(ans == 64'h7FF0000000000000) $fwrite(fp, \"ans=+inf \");\n");
			fprintf(fq,"		if(ans >  64'h7FF0000000000000 && ans <  64'h7FF8000000000000 ) $fwrite(fp, \"ans=sigNaN \");\n");
			fprintf(fq,"		if(ans >  64'hFFF8000000000000 && ans <  64'hFFF8000000000000 ) $fwrite(fp, \"ans=sigNaN \");\n");
			fprintf(fq,"		if(ans >= 64'h7FF8000000000000 && ans <= 64'h7FFfffffffffffff ) $fwrite(fp, \"ans=qutNaN \");\n");
			fprintf(fq,"		if(ans >= 64'hFFF8000000000000 && ans <= 64'hFFFfffffffffffff ) $fwrite(fp, \"ans=qutNaN \");\n");
			}//end else

			fprintf(fq,"    	$fwrite(fp,\"%s \");\n",flags);

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


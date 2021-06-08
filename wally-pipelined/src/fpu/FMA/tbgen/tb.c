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
		char ReadData1E[17];
		char ReadData2E[17];
		char ReadData3E[17];
		char ans[81];
		char flags[3];
		int FrmE;
		long stop = 5587581;
		int debug = 0;
		//my_string = (char *) malloc (nbytes + 1);
		//bytes_read = getline (&my_string, &nbytes, stdin);
	

		for(n=0; n < 1000; n++) {//613 for 10000
			if(getline(&ln,&nbytes,fp) < 0 || feof(fp)) break;
			if(k == stop && debug == 1) break;
			k++;
		}
		//fprintf(stderr,"%s\n", ln);

		if(!feof(fp)) {

			strncpy(ReadData1E,   ln,     16); ReadData1E[16]=0;
			strncpy(ReadData2E,    &ln[17], 16); ReadData2E[16]=0;
			strncpy(ReadData3E,  &ln[34], 16); ReadData3E[16]=0;
			// fprintf(stdout,"[%s]\n[%s]\n", ln,ReadData3E);
			strncpy(ans,  &ln[51], 16); ans[16]=0;
			strncpy(flags,&ln[68],2);   flags[2]=0;
		
			// fprintf(stdout,"[%s]\n[%s]\n", ln,ReadData3E);
			fprintf(fq,"    ReadData1E = 64'h%s;\n",ReadData1E); 
			fprintf(fq,"    ReadData2E = 64'h%s;\n",ReadData2E); 
			fprintf(fq,"    ReadData3E = 64'h%s;\n",ReadData3E);
			fprintf(fq,"    ans = 64'h%s;\n", ans);
			// fprintf(fq,"    flags = 5'h%s;\n", flags);
		

			{
				//rn=1; rz=0; rm=0; rp=0;
				fprintf(fq,"    FrmE = 3'b000;\n");
			}
			fprintf(fq,"#10\n");
			// IEEE 754-2008 section 6.3 states "When ether an input or result is NaN, this standard does not interpret the sign of a NaN."
			//fprintf(fq,"	$fwrite(fp, \"%%h %%h %%h %%h \",ReadData1E,ReadData2E,FmaResultM, ans);\n");	
			fprintf(fq,"    // IEEE 754-2008 section 6.3 states: \"When ether an input or result is NaN, this\n");
			fprintf(fq,"    //                                     standard does not interpret the sign of a NaN.\"\n");
			fprintf(fq,"	wnan = &FmaResultM[62:52] && |FmaResultM[51:0]; \n");
			fprintf(fq,"	xnan = &ReadData1E[62:52] && |ReadData1E[51:0]; \n");
			fprintf(fq,"	ynan = &ReadData2E[62:52] && |ReadData2E[51:0]; \n");
			fprintf(fq,"	znan = &ReadData3E[62:52] && |ReadData3E[51:0]; \n");
			fprintf(fq,"	ansnan = &ans[62:52] && |ans[51:0]; \n");
			fprintf(fq,"	xnorm = ~(|ReadData1E[62:52]) && |ReadData1E[51:0] ? {ReadData1E[50:0], 1'b0} : ReadData1E; \n");
			fprintf(fq,"	ynorm = ~(|ReadData2E[62:52]) && |ReadData2E[51:0] ? {ReadData2E[50:0], 1'b0} : ReadData2E;\n");
			// fprintf(fq,"	s = ({54'b1,xnorm} + (bypsel  && bypplus1))  *  {54'b1,ynorm}; \n");
			// fprintf(fq,"    if(!(~(|ReadData1E[62:52]) && |ReadData1E[51:0] || ~(|ReadData2E[62:52]) && |ReadData2E[51:0])) begin\n"); 
																							// not looknig at negative zero results right now
			//fprintf(fq,"	  if( (nan && (FmaResultM[62:0] != ans[62:0])) || (!nan && (FmaResultM != ans)) && !(FmaResultM == 64'h8000000000000000 && ans == 64'b0)) begin\n"); 
			// fprintf(fq,"	if( (nan && (FmaResultM[62:0] != ans[62:0])) || (!nan && (FmaResultM != ans)) ) begin\n"); 
			fprintf(fq,"	if((!wnan && (FmaResultM != ans)) || (wnan && ansnan && ~(((xnan && (FmaResultM[62:0] == {ReadData1E[62:52],1'b1,ReadData1E[50:0]})) || (ynan && (FmaResultM[62:0] == {ReadData2E[62:52],1'b1,ReadData2E[50:0]}))  || (znan && (FmaResultM[62:0] == {ReadData3E[62:52],1'b1,ReadData3E[50:0]})) || (FmaResultM[62:0] == ans[62:0])) ))) begin\n"); 
			fprintf(fq,"		$fwrite(fp, \"%%h %%h %%h %%h %%h  Wrong \",ReadData1E,ReadData2E, ReadData3E, FmaResultM, ans);\n");
			//fprintf(fq,"		$fwrite(fp, \"%%h \",s);\n");
			fprintf(fq,"		$fwrite(fp, \"FmaResultM=%%d \",$signed(aligncntE));\n");
			fprintf(fq,"		if(FmaResultM == 64'h8000000000000000) $fwrite(fp, \"FmaResultM=-zero \");\n");
			fprintf(fq,"		if(~(|ReadData1E[62:52]) && |ReadData1E[51:0]) $fwrite(fp, \"xdenorm \");\n");
			fprintf(fq,"		if(~(|ReadData2E[62:52]) && |ReadData2E[51:0]) $fwrite(fp, \"ydenorm \");\n");
			fprintf(fq,"		if(~(|ReadData3E[62:52]) && |ReadData3E[51:0]) $fwrite(fp, \"zdenorm \");\n");
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


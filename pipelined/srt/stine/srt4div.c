#include "disp.h"
#include <math.h>

int qslc (double prem, double d) {

  int q;

  printf("d  --> %lg\n", d);
  printf("rw --> %lg\n", prem);
  if ((d>=0.0)&&(d<1.0)) {
    if (prem>=1.0)
       q = 2;
    else if (prem>=0.25)
      q = 1;
    else if (prem>=-0.25)
      q = 0;
    else if (prem >= -1)
      q = -1;
    else 
      q = -2;
    return q;
  }

  if ((d>=1.0)&&(d<2.0)) {
    if (prem>=2.0)
       q = 2;
    else if (prem>=0.66667)
      q = 1;
    else if (prem>=-0.6667)
      q = 0;
    else if (prem >= -2)
      q = -1;
    else 
      q = -2;
    return q;
  }

  if ((d>=2.0)&&(d<3.0)) {
    if (prem>=4.0)
       q = 2;
    else if (prem>=1.25)
      q = 1;
    else if (prem>=-1.25)
      q = 0;
    else if (prem >= -4)
      q = -1;
    else 
      q = -2;
    return q;
  }

  if ((d>=3.0)&&(d<4.0)) {
    if (prem>=5.0)
       q = 2;
    else if (prem>=2.0)
      q = 1;
    else if (prem>=-2.0)
      q = 0;
    else if (prem >= -5)
      q = -1;
    else 
      q = -2;
    return q;
  }

  if ((d>=4.0)&&(d<5.0)) {
    if (prem>=6.66667)
       q = 2;
    else if (prem>=2.0)
      q = 1;
    else if (prem>=-2.0)
      q = 0;
    else if (prem >= -6.66667)
      q = -1;
    else 
      q = -2;
    return q;
  }

  if ((d>=5.0)&&(d<6.0)) {
    if (prem>=8.0)
       q = 2;
    else if (prem>=2.0)
      q = 1;
    else if (prem>=-2.0)
      q = 0;
    else if (prem >= -8.0)
      q = -1;
    else 
      q = -2;
    return q;
  }

  if ((d>=6.0)&&(d<7.0)) {
    if (prem>=10.0)
       q = 2;
    else if (prem>=4.0)
      q = 1;
    else if (prem>=-4.0)
      q = 0;
    else if (prem >= -10.0)
      q = -1;
    else 
      q = -2;
    return q;
  }

  if ((d>=7.0)&&(d<8.0)) {
    if (prem>=11.0)
       q = 2;
    else if (prem>=4.0)
      q = 1;
    else if (prem>=-4.0)
      q = 0;
    else if (prem >= -11.0)
      q = -1;
    else 
      q = -2;
    return q;
  }

  if ((d>=8.0)&&(d<9.0)) {
    if (prem>=12.0)
       q = 2;
    else if (prem>=4.0)
      q = 1;
    else if (prem>=-4.0)
      q = 0;
    else if (prem >= -12.0)
      q = -1;
    else 
      q = -2;
    return q;
  }

  if ((d>=9.0)&&(d<10.0)) {
    if (prem>=15.0)
       q = 2;
    else if (prem>=4.0)
      q = 1;
    else if (prem>=-4.0)
      q = 0;
    else if (prem >= -15.0)
      q = -1;
    else 
      q = -2;
    return q;
  }

  if ((d>=10.0)&&(d<11.0)) {
    if (prem>=15.0)
       q = 2;
    else if (prem>=4.0)
      q = 1;
    else if (prem>=-4.0)
      q = 0;
    else if (prem >= -15.0)
      q = -1;
    else 
      q = -2;
    return q;
  }

  if ((d>=11.0)&&(d<12.0)) {
    if (prem>=16.0)
       q = 2;
    else if (prem>=4.0)
      q = 1;
    else if (prem>=-4.0)
      q = 0;
    else if (prem >= -16.0)
      q = -1;
    else 
      q = -2;
    return q;
  }

  if ((d>=12.0)&&(d<13.0)) {
    if (prem>=20.0)
       q = 2;
    else if (prem>=8.0)
      q = 1;
    else if (prem>=-8.0)
      q = 0;
    else if (prem >= -20.0)
      q = -1;
    else 
      q = -2;
    return q;
  }

  if ((d>=13.0)&&(d<14.0)) {
    if (prem>=20.0)
       q = 2;
    else if (prem>=8.0)
      q = 1;
    else if (prem>=-8.0)
      q = 0;
    else if (prem >= -20.0)
      q = -1;
    else 
      q = -2;
    return q;
  }

  if ((d>=14.0)&&(d<15.0)) {
    if (prem>=20.0)
       q = 2;
    else if (prem>=8.0)
      q = 1;
    else if (prem>=-8.0)
      q = 0;
    else if (prem >= -20.0)
      q = -1;
    else 
      q = -2;
    return q;
  }

  if ((d>=15.0)&&(d<16.0)) {
    if (prem>=24.0)
       q = 2;
    else if (prem>=8.0)
      q = 1;
    else if (prem>=-8.0)
      q = 0;
    else if (prem >= -24.0)
      q = -1;
    else 
      q = -2;
    return q;
  }

}

/*
 This routine performs a radix-4 SRT division 
 algorithm.  The user inputs the numerator, the denominator, 
 and the number of iterations. It assumes that 0.5 <= D < 1.
        
*/

int main(int argc, char* argv[]) {

   double P, N, D, Q, RQ, RD, RREM, scale;   
   int q;
   int num_iter, i;
   int prec;
   if (argc < 5) {
      fprintf(stderr,
	      "Usage: %s numerator denominator num_iterations prec\n", 
	      argv[0]);
      exit(1);
   }
   sscanf(argv[1],"%lg", &N);
   sscanf(argv[2],"%lg", &D);
   sscanf(argv[3],"%d", &num_iter);
   sscanf(argv[4],"%d", &prec);
   // Round to precision
   N = rne(N, prec);
   D = rne(D, prec);
   printf("N = ");
   disp_bin(N, 3, prec, stdout);
   printf("\n");
   printf("D = ");
   disp_bin(D, 3, prec, stdout);
   printf("\n");

   Q = 0;
   P = N*0.25;
   printf("N = %lg, D = %lg, N/D = %lg, num_iter = %d \n\n", 
	  N, D, N/D, num_iter); 
   for (scale = 1, i = 0; i < num_iter; i++) {
     // Shift by r
     scale = scale*0.25;
     q = qslc(flr((4*P)*16,3), D*16);
     //q = -q;
     printf("4*W[n] = ");
     disp_bin(4*P,3,prec,stdout);
     printf("\n");
     printf("q*D = ");      
     disp_bin(q*D,3,prec,stdout);
     printf("\n");
     printf("W[n+1] = ");            
     disp_bin(P ,3,prec,stdout);
     printf("\n");
     // Recurrence
     P = 4*P - q*D;
     // OTFC
     Q = Q + q*scale;
     printf("i = %d, q = %d, Q = %1.18lf, W = %1.18lf\n", i, q, Q, P); 
     printf("i = %d, q = %d", i, q);
     printf(", Q = ");
     disp_bin(Q, 3, prec, stdout);
     printf(", W = ");
     disp_bin(P, 3, prec, stdout);
     printf("\n\n");
   }
   if (P < 0) {
     Q = Q - scale;
     P = P + D;
     printf("\nCorrecting Negative Remainder\n"); 
     printf("Q = %1.18lf, W = %1.18lf\n", Q, P); 
     printf("Q = ");
     disp_bin(Q, 3, prec, stdout);
     printf(", W = ");
     disp_bin(P, 3, prec, stdout);
     printf("\n");
   } 
   RQ = flr(N/D, (double) prec);
   RD = Q*4;
   printf("true = %1.18lf, computed = %1.18lf, \n", RQ, RD);
   printf("true = ");
   disp_bin(RQ, 3, prec, stdout);
   printf(", computed = ");
   disp_bin(RD, 3, prec, stdout);
   printf("\n\n");
   printf("REM = %1.18lf \n", P);
   printf("REM = ");
   disp_bin(P, 3, prec, stdout);
   printf("\n\n");

   return 0;

}

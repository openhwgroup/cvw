#include "disp.h"

// QSLC is for division by recuerrence for
// r=2 using a CPA - See 5.109 EL
int qst (double D, double prem) {

  int q;

  // For Debugging
  printf("rw --> %lg\n", prem);  

  if (prem >=  0.5) {
    q = 1;
  } else if (prem >= -0.5) {
    q = 0;
  } else {
    q = -1;
  }
  return q;

}

/*
 This routine performs a radix-2 SRT division 
 algorithm.  The user inputs the numerator, the denominator, 
 and the number of iterations. It assumes that 0.5 <= D < 1.
        
*/

int main(int argc, char* argv[]) {

   double P, N, D, Q, RQ, RD, RREM, scale;   
   int q;
   int num_iter, i;
   int prec;
   int radix = 2;
   
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
   P = N * pow(2.0, -log2(radix));
   printf("N = %lg, D = %lg, N/D = %lg, num_iter = %d \n\n", 
	  N, D, N/D, num_iter); 
   for (scale = 1, i = 0; i < num_iter; i++) {
     scale = scale * pow(2.0, -log2(radix));
     q = qst(flr(2*D, 1), 2*P);
     printf("2*W[n] = ");
     disp_bin(radix*P, 3, prec, stdout);
     printf("\n");
     printf("q*D = ");      
     disp_bin(q*D, 3, prec, stdout);
     printf("\n");
     printf("W[n+1] = ");            
     disp_bin(P ,3, prec, stdout);
     printf("\n");     
     // Recurrence
     P = radix * P - q * D;
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

   // Output Results
   RQ = N/D;
   // Since q_{computed} = q / radix, multiply by radix
   RD = Q * radix;
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

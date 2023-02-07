// Kevin Box
//kbox@hmc.edu

#include <stdio.h>  // supports printf
#include <math.h>   // supports fabs
#include "util.h"   // supports verify


void matrixMult(int N, double *A, double *B, double *Y) {
  // code adapted from E85 lab6 code written by me
  // Need to initilize all values of Y to zero
  for (int i = 0; i<N; i++) {
       Y[i] = 0;
    } 
  int row, col;
  for (row=0; row<N; row++) {
    for (col=0; col<N; col++){
    int i;
      for (i = 0; i<N; i++){
       Y[row*N+col]+=A[row*N + i]*B[col + i*N];
      }

    }
  }

}


int main(void) {
   
    int n = 10;
    int N = n*n;
    double X[N];
    double Y[N];
    double Z[N];
    
    for (int i = 0; i<N; i++) {
        X[i] = i+1.0;
        Y[i] = N-i-1.0;
    }
    

    double Zexp1[1];
    Zexp1[0] = 0;
    double Zexp2[4];
    Zexp2[0] = 5;
    Zexp2[1] = 2;
    Zexp2[2] = 13;
    Zexp2[3] = 6;
    double Zexp3[9];
    Zexp3[0] = 24;
    Zexp3[1] = 18;
    Zexp3[2] = 12;
    Zexp3[3] = 69;
    Zexp3[4] = 54;
    Zexp3[5] = 39;
    Zexp3[6] = 114;
    Zexp3[7] = 90;
    Zexp3[8] = 66;

    double *expectedZ[3];

    expectedZ[0] = Zexp1;
    expectedZ[1] = Zexp2;
    expectedZ[2] = Zexp3;


/* expected output of 4x4 did not want to hardcode but for testing reference 
	C1	C2	C3	C4
1	70	60	50	40
2	214	188	162	136
3	358	316	274	232
4	502	444	386	328
*/


    /* expected output of 5x5 did not want to hardcode but for testing reference 
    C1  C2	C3	C4	C5
1	160	145	130	115	100
2	510	470	430	390	350
3	860	795	730	665	600
4	1210 1120 1030 940 850
5	1560 1445 1330 1215 1100
    */
    setStats(1);
    matrixMult(n, X, Y, Z);
    setStats(0);
    // library linked doesn't support printing doubles, so convert to integers to print
    for (int i=0; i<N; i++)  {
        int tmp = Z[i];
        printf("Z[%d] = %d\n", i, tmp);
    }

    // verifyDouble doesn't work exaclty because of rounding, so check for almost equal
    // Checking works for all given matrix SIZE N<=3 just change t
    for (int i=0; i<N; i++) {
        if (n <= 3) {
            if (fabs(Z[i] - expectedZ[n][i]) > 1e-10) {
                return 1;
            }
        }
    }
    return 0;
}
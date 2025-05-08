// fir.c
// David_Harris@hmc.edu 20 January 2022
// Finite Impulse Response Filter

#include <stdio.h>  // supports printf
#include <math.h>   // supports fabs
#include "util.h"   // supports verify

void fir(int N, int M, double X[], double c[], double Y[]) {
  int i, n;
  double sum; 

  for (n=0; n<N; n++) {
      sum = 0;
      for (i=0; i<M; i++) {
          sum += c[i]*X[n-i+(M-1)];
      }
      Y[n] = sum;
  }
}

int main(void) {
    double X[20] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20};
    double c[5] = {0.2, 0.2, 0.2, 0.2, 0.2};
    double Y[15];
    double Yexpected[15] = {3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17}; 
 
    setStats(1);
    fir(15, 5, X, c, Y);
    setStats(0);
    // library linked doesn't support printing doubles, so convert to integers to print
    for (int i=0; i<15; i++)  {
        int tmp = Y[i];
        printf("Y[%d] = %d\n", i, tmp);
    }
    // verifyDouble doesn't work exactly because of rounding, so check for almost equal
    for (int i=0; i<15; i++) {
        if (fabs(Y[i] - Yexpected[i]) > 1e-10) {
            return 1;
        }
    }
    return 0;
}
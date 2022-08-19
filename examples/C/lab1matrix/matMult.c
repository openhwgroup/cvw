// matMult.c
// mmasserfrye@hmc.edu 30 January 2022

#include <stdio.h>  // supports printf
#include <math.h>   // supports fabs
#include "util.h"   // supports verify

// puts the indicated row of length n from matrix mat into array arr
void getRow(int n, int row, double *mat, double *arr){
    int ind;
    for (int i=0; i<n; i++){
        ind = i+row*n;
        arr[i] = mat[ind];
    }
}

// computes the dot product of arrays a and b of length n
double dotproduct(int n, double a[], double b[]) {

    volatile int i;
    double sum;
    sum = 0;

    for (i=0; i<n; i++) {
        if (i==0) sum=0;
        sum += a[i]*b[i];
    }
    return sum;
}

// multiplies matrices A (m1 x n1m2) and B (n1m2 x n2) and puts the result in Y
void mult(int m1, int n1m2, int n2, double *A, double *B, double *Y) {

    // transpose B into Bt so we can dot product matching rows
    double Bt[n2*n1m2];
    int ind;
    int indt;
    for (int i=0; i<n1m2; i++){
        for (int j=0; j<n2; j++){
            ind = i*n2+j;
            indt = j*n1m2+i;
            Bt[indt] = B[ind];
        }
    }

    int indY;
    double Arow[n1m2];
    double Bcol[n1m2];

    for (int i=0; i<m1; i++){
        for (int j=0; j<n2; j++){
            indY = i*n2+j;
            getRow(n1m2, i, A, Arow);
            getRow(n1m2, j, Bt, Bcol);
            Y[indY] = dotproduct(n1m2, Arow, Bcol);
        }
    }
}

int main(void) {

    // change these bits to test stuff
    int m = 20;
    int n = 1;
    double X[20]; // change to m*n
    double Y[400]; // change to m^2

    // fill in some numbers so the test feels legit
    for (int i=0; i<n; i++){
        X[i] = i;
    }
 
    setStats(1);
    mult(m, n, m, X, X, Y);
    setStats(0);

    /*
    // use this code from Harris's fir.c to print matrix one element at a time
    // library linked doesn't support printing doubles, so convert to integers to print
    for (int i=0; i<m*m; i++)  {
        int tmp = Y[i];
        printf("Y[%d] = %d\n", i, tmp);
    }
    */
    return 0;
    
}
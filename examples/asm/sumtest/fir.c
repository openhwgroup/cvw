// fir.C
// David_Harris@hmc.edu 25 December 2021
// Finite Impulse Response Filter

#include <math.h>

#define N 2000
#define M 100
#define PI 3.14159

double fir(double a[], double c[], double y[], int N, int M) {
    int i, j
    for (i=0; i<N-M; i++) {
        y[i] = 0;
        for (j=0; j<M; j++) {
            y[i] += c[j] * a[M+i-j];
        }
    }
}

int main(void) {
    double a[N], c[M], y[N-M];

    int i;

    // // step input with overlying high frequency sinusoid
    for (i=0; i<N; i++) a[i] = (i < N/2) + 0.5 * cos(2*PI*i/50); 

    // filter coeffieints: replace with a sinc function with sharper response
    //for (i=0; i<M; i++) c[i] = 1.0/M; // low pass filter with equal coefficients
    for (i=0; i<M; i++) c[i] = 2.0*B*(sin(2.0*B*i/10)/(2.0*B*i/10)); // low pass filter with equal coefficients

    // inline assembly to measure time, with macro
    fir(a, c, y, N, M);
    // measure time again
    // *** generate signature
    // *** write_tohost
}
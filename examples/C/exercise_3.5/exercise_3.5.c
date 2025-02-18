#include <stdio.h>
#include "util.h"
// Matrix-vector multiplication y = Ax.  
// A is an m rows x n columns matrix.
void matvecmul(int A[], int x[], int y[], int m, int n) {
 	int i, j, sum;
	for (i=0; i<m; i = i + 1) {
		sum = 0;
		for (j=0; j<n; j = j + 1) 
			sum = sum + A[i*n+j] * x[j];
		y[i] = sum;
	}
}

int main(void) {
  int A[6] = {1, 2, 3, 4, 5, 6};
  int x[3] = {7, 8, 9};
  int y[2];
  int expected[2] = {50, 122}; //  -- line added for exercise_3.6
  setStats(1); // record initial mcycle and minstret -- line added for exercise_3.6
  matvecmul(A, x, y, 2, 3);
  setStats(0); // record elapsed mcycle and minstret -- line added for exercise_3.6
  printf("y = [%d %d]\n", y[1], y[0]);  // print result, which should be [122 50] -- line added for exercise_3.6
  return verify(2,y,expected); // -- line added for exercise_3.6
}

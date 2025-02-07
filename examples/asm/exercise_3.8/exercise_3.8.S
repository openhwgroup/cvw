# void fir(int x[], int c[], int y[], int n, int m) {
#     int j, i;
#     int sum;
#     for (j=0;j<(n-m+1);j++) {
#         sum = 0;
#         for (i=0;i<m;i++) {
#             sum = add_q31(sum,mul_q31(c[i],x[j-i+m-1]));
#         }
#         y[j] = sum;
#     }
# }

// a0 <- x
// a1 <- c
// a2 <- y
// a3 <- n
// a4 <- m
.global fir
fir:
    
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
    # precompute address of y[n-m+1] at end of j loop
    sub  t0, a3, a4     # n - m, for checking end of j loop
    addi t0, t0, 1      # n - m + 1 for checking end of j loop
    slli t0, t0, 2      # convert fron words to bytes
    add  t0, a2, t0     # &y[n-m+1]
    # precompute address of c[m] at end of i loop
    slli t1, a4, 2      # convert m from words to bytes
    add  t1, a1, t1     # &c[m] 
    # initialize address of x[m-1] for accessing x0
    addi t2, a4, -1     # m-1
    slli t2, t2, 2      # convert from words to bytes
    add  t2, a0, t2     # &x[m-1]

    # start of j loop
    # no variable for j; instead use a2 as pointer to y[j] and t2 as pointer to x[j+(m-1)]
forj:
    bge a2, t0, donej   # j loop is done when j >= n-m+1

    # body of j loop
    li t3, 0            # sum = 0

    # start of i loop
    # i = 0
    # no variable for i; instead, use t3 as pointer to c[i]
    mv t4, a1           # t4 = &c[0]
    mv t5, t2           # t5 = &x[j+(m-1)]
    
fori:
    bge t4, t1, donei   # i loop is done when i >= m

    # body of i loop
    lw t6, 0(t4)        # t6 = c[i]; sign extend to 64 bits
    lw a5, 0(t5)        # a5 = x[j-i+(m-1)]; sign extend to 64 bits
    mul t6, t6, a5      # signed 32 x 32 -> 64 bit multiplication
    srai t6, t6, 31     # shift right by 31.  Upper bits become sign bit
    addw t3, t3, t6     # sum = sum + shifted product

    # i++
    addi t4, t4, 4      # increment c[i] pointer to next element (i++)
    addi t5, t5, -4     # decrement x[j-i+(m-1)] pointer to next element
    j fori              # repeat loop

donei:
    sw t3, 0(a2)        # y[j] = sum
    # j++
    addi a2, a2, 4      # increment y[j] pointer to next element (j++)
    addi t2, t2, 4      # increment x[j+m-1] pointer to next element
    j forj

donej:
    ret                 # all done; return

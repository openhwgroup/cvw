// fir.s
// mmasserfrye@hmc.edu 30 January 2022
// FIR filter

// a0 = N, a1 = M, a2 = &X, a3 = &c, a4 = &Y

.global fir

fir:
    li t0, 0          # n = 0 = t0
    slli t6, a0, 3    # N*8
    slli t5, a1, 3    # M*8
    addi t4, t5, -8   # (M-1)*8
for1:
    bge t0, t6, end   # exit outer for if n >= N
    fmv.d.x f3, zero  # sum = 0 = f3
    li t2, 0          # i = 0 = t2
    add t1, t4, t0    # [(M-1) + n]*8
for2:
    bge t2, t5, for1end  # exit inner for if i >= M
    sub t3, t1, t2    # [(M-1) + n - i]*8  
    add t3, t3, a2    # t3 = offset + &X
    fld f0, 0(t3)     # X[n-i+(M-1)] 
    add t3, t2, a3    # t3 = offset + &c
    fld f1, 0(t3)     # c[i] 
    fmadd.d f3, f0, f1, f3  # sum += c[i]*X[n-i+(M-1)]
    addi t2, t2, 8    # i++
    j for2
for1end:
    add t3, t0, a4    # t3 = offset + &Y
    fsd f3, 0(t3)     # Y[n] = sum
    addi t0, t0, 8    # n++
    j for1
end:
    ret
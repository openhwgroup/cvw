#fir.S
#Kevin Box
#kbox@hmc.edu

.global fir
fir:
    blez a0, Done
    addi sp, sp, -16 # sp =sp-16 # make space in s0 and s1
    sd s0, 8(sp) #save s0 and s1 to stack to make space
    sd s1, 16(sp)
    addiw s1, a1, -1 #compute M-1 out of loop to be used later 
    li s0, 0 #n = 0

OuterLoop:
    beq s0, a0, Restore # if s0 == a0 then restore
    fmv.d.x f3, zero #sum=0
    li t0, 0 # t0 =0 

InnerLoop:
    beq a1, t0, Increment_n # if a1 ==t0 then Increment_n
    slli t2, t0, 3 #t2 = 8*i (index if c[i])
    add t2, t2, a3 #t2 gets adress of c[i]
    sub t4, s0, t0 #t4 = n-i
    add t3, t4, s1 #t3 = n-i+(M-1)
    slli t3, t3, 3 #t3 = 8(n-i+(M-1)) index of X[n-i+(M-1)]
    add t3, t3, a2 #t3 gets address of X[n-i+(M-1)]
    fld f0, 0(t2) #ft0 = C[i]
    fld f1, 0(t3) #ft1 = X[n-i+(M-1)]
    fmul.d f2, f0, f1 #ft2 = C[i]*X[n-i+(M-1)]
    fadd.d f3, f3, f2 # sum = sum+C[i]*X[n-i+(M-1)]
    addi t0, t0, 1 #increment i
    j InnerLoop

Increment_n:
    slli t1, s0, 3 #t1 = 8*n (index of Y[n])
    add t1, t1, a4 #t1 gets address of Y[n]
    fsd f3, 0(t1) #save Y[n] = sum
    addi s0, s0, 1 # n = n+1
    j OuterLoop 

Restore:
    ld s0, 8(sp) # make space in s0 and s1
    ld s1, 16(sp)
    addi sp, sp, 16 # sp =sp+16

Done:
    ret


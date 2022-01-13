// sum.s
// David_Harris@hmc.edu 24 December 2021
// Add up numbers from 1 to N.

// result in s0, i in s1, N in a0, return answer in a0
//
// long sum(long N) {
//   long result, i;
//   result = 0;
//   for (i=1; i<=N; i++) result = result + i;
//   return result;
// }

.global sum
sum:
    addi sp, sp, -16    # make room to save s0 and s1 on the stack
    sd s0, 0(sp)
    sd s1, 8(sp)

    li s0, 0            # result = 0
    li s1, 1            # i = 1
for: bgt s1, a0, done   # exit loop if i > n
    add s0, s0, s1      # result = result + i
    addi s1, s1, 1      # i++
    j for               # repeat

done:
    mv a0, s0           # put result in a0 to return
    ld s0, 0(sp)        # restore s0 and s1 from stack
    ld s1, 8(sp)
    addi sp, sp, 16  
    ret                 # return from function

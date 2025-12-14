.section .text
.global _start

_start:
    vsetvli t0, a5, e64,m1,ta,mu
    vfadd.vv v8, v8, v9

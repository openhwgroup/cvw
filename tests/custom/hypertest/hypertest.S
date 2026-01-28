.option norvc
.section .text.start
.globl _start

_start:
  # HSTATUS: VTSR (22) and VTVM (20)
  li t0, 0x00500000
  csrw hstatus, t0
  csrr t1, hstatus
  li t2, 0x00500000
  and t1, t1, t2
  bne t1, t0, fail

  # HEDELEG: low 16 bits
  li t0, 0xA5A5
  csrw hedeleg, t0
  csrr t1, hedeleg
  li t2, 0xFFFF
  and t1, t1, t2
  bne t1, t0, fail

  # HIDELEG: low 12 bits
  li t0, 0x5A5
  csrw hideleg, t0
  csrr t1, hideleg
  li t2, 0x0FFF
  and t1, t1, t2
  bne t1, t0, fail

  # HCOUNTEREN
  li t0, 0x5
  csrw hcounteren, t0
  csrr t1, hcounteren
  bne t1, t0, fail

  # VSSTATUS: MXR, SUM, FS=01, SPP, SPIE, SIE
  li t0, 0x000C2122
  csrw vsstatus, t0
  csrr t1, vsstatus
  li t2, 0x000C2122
  and t1, t1, t2
  bne t1, t0, fail

  # VSTVEC: aligned base, unvectored
  li t0, 0x80000040
  csrw vstvec, t0
  csrr t1, vstvec
  li t2, 0x80000040
  bne t1, t2, fail

success:
  # Emit jal x0, 0 to signal testbench completion.
  .word 0x0000006f

fail:
  beq x0, x0, fail

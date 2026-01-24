.option norvc
.section .text.start
.globl _start

_start:
  # Trap handler for illegal CSR writes.
  la t0, m_trap
  csrw mtvec, t0

  li s1, 0

  # HIP (0x644) is read-only; write should trap.
  la s0, hip_write
  li t0, -1
hip_write:
  csrw hip, t0
hip_after:
  li t1, 1
  bne s1, t1, fail

  # HGEIP (0xE12) is read-only; write should trap.
  la s0, hgeip_write
  li t0, -1
hgeip_write:
  csrw hgeip, t0
hgeip_after:
  li t1, 2
  bne s1, t1, fail

success:
  # Emit jal x0, 0 to signal testbench completion.
  .word 0x0000006f

fail:
  beq x0, x0, fail

m_trap:
  # Expect illegal instruction from read-only CSR write.
  csrr t0, mcause
  li t1, 0x7fffffff
  and t0, t0, t1
  li t1, 2
  bne t0, t1, fail

  # Ensure the trap came from the expected CSR write.
  csrr t2, mepc
  bne t2, s0, fail

  addi s1, s1, 1
  addi t2, t2, 4
  csrw mepc, t2
  mret

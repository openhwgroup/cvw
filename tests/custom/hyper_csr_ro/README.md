# hyper_csr_ro

Purpose
  Validate that read-only hypervisor CSRs (HIP 0x644, HGEIP 0xE12) raise an illegal-instruction trap when written in M-mode.

Flow
  1) Set mtvec to m_trap and clear s1 (trap counter).
  2) Attempt csrw HIP with s0 pointing at the faulting instruction label.
  3) m_trap checks mcause==2, verifies mepc==s0, increments s1, advances mepc by 4, and mret returns to hip_after.
  4) Repeat for HGEIP; expect s1==2 after the second trap.
  5) Emit jal x0,0 to finish; otherwise spin in fail.

Notes
  - .option norvc ensures the faulting instruction is 4 bytes so mepc+4 is correct.
  - If the core does not trap on read-only CSR writes, the watchdog will time out.

Build and run
  make -C tests/custom/hyper_csr_ro
  bin/wsim rv32gc --elf tests/custom/hyper_csr_ro/bin/hyper_csr_ro.elf

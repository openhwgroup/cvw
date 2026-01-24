# hyper_csr_basic

Purpose
  Sanity-check writable hypervisor CSRs in M-mode by doing write/readback on a few implemented fields.

Flow
  1) HSTATUS: set VTSR (bit 22) and VTVM (bit 20), read back, and mask-check.
  2) HEDELEG: write a 16-bit pattern and verify low 16 bits match.
  3) HIDELEG: write a 12-bit pattern and verify low 12 bits match.
  4) HCOUNTEREN: write a small pattern and verify readback.
  5) Emit jal x0,0 to finish; otherwise spin in fail.

Notes
  - This does not enter VS/HS modes; it only validates CSR storage logic in M-mode.
  - Masking avoids false failures if upper bits are hard-wired or reserved.

Build and run
  make -C tests/custom/hyper_csr_basic
  bin/wsim rv32gc --elf tests/custom/hyper_csr_basic/bin/hyper_csr_basic.elf

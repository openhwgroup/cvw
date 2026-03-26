//////////////////////////////////////////////////////////////////////
// WALLY-debug-03.S - CSR reads/writes
//////////////////////////////////////////////////////////////////////
.text
.globl rvtest_entry_point
rvtest_entry_point:
   la   t2, begin_signature

   # Set t0 = 42, then read debug CSRs
   li   t0, 42            # t0 = 42

   csrr a0, dcsr          # read dcsr      -> a0
   csrr a1, dscratch0     # read dscratch0 -> a1
   csrr a2, dscratch1     # read dscratch1 -> a2

test1:
   sd a0, 0(t2)           # dcsr value
   sd a1, 8(t2)           # dscratch0 value
   sd a2, 16(t2)          # dscratch1 value
   addi t2, t2, 24
1: j 1b

test_end:
   j tohost_exit

.globl tohost_exit
tohost_exit:
   slli a0, a0, 1
   ori a0, a0, 1
   la t0, tohost
   sw a0, 0(t0)
1: j 1b

.data

begin_signature:
   .fill 3*2, 4, 0xdeadbeef
end_signature:

.section .tohost, "aw", @progbits
.align 6
.globl tohost
tohost: .dword 0

.align 6
.globl fromhost
fromhost: .dword 0

.align 6
magic_mem: .word 0, 0, 0, 0, 0, 0, 0, 0

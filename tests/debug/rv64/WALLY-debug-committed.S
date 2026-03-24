//////////////////////////////////////////////////////////////////////
// WALLY-debug-step-committed.S
//
// This test is for ensuring that the Debug halting state machine
// waits for committed bus transactions before finally halting.
//////////////////////////////////////////////////////////////////////
.text
.globl rvtest_entry_point
rvtest_entry_point:
   la t1, begin_signature
   # Dummy trap handler
   la t0, trap_handler
   csrw mtvec, t0

halt1:
   # Infinite loop here instead of ebreak. Ebreak introduces trigger
   # module register reads in OpenOCD for some reason. Until this is
   # configurable in Spike or until we actually have trigger modules
   # in Wally, we don't want these extra testvectors cluttering the
   # output.
   j .

dosteps:
   # stepping through all of this code should cause writes to the
   # memory signature.
   li t0, 0x00ba771e
   sw t0, 0(t1)
   addi t0, t0, 1
   addi t0, t0, 2
   addi t0, t0, 3
   addi t0, t0, 4
   addi t0, t0, 5
   addi t0, t0, 6
   addi t0, t0, 7
   addi t0, t0, 8
   addi t0, t0, 9
   addi t0, t0, 10
   addi t0, t0, 11
   addi t0, t0, 12
   addi t0, t0, 13
   addi t0, t0, 14
   addi t0, t0, 15
   addi t0, t0, 16
   addi t0, t0, 17
   addi t0, t0, 18
   addi t0, t0, 19
   addi t0, t0, 20
   addi t0, t0, 21
   addi t0, t0, 22
   addi t0, t0, 23
   addi t0, t0, 24

test_end:
   # fence.i
   li a0, 0
   j tohost_exit

.globl tohost_exit
tohost_exit:
   slli a0, a0, 1
   ori a0, a0, 1
   la t0, tohost
   sw a0, 0(t0)
1: j 1b

trap_handler:
   j .

.data
# Spike memory regions ###############################################
begin_signature:
   .fill 1*2, 4, 0xdeadbeef
end_signature:

.section .tohost, "aw", @progbits
.align 6
.globl tohost
tohost: .dword 0

.align 6
.globl fromhost
fromhost: .dword 0

# a syscall buffer?
.align 6
magic_mem: .word 0, 0, 0, 0, 0, 0, 0, 0

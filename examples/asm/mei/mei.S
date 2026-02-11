// mei.S
// David_Harris@hmc.edu 10 Feb 2026
//
// Demonstrates generating a machine external interrupt using NS16550 UART
// The UART device is at 0x10000000 and generates PLIC interrupt ID 1

# Following parameter needs to be set based on the UART SRC ID for the DUT
#.EQU UART_INT_SRC, 10  # For CVW
.EQU UART_INT_SRC, 1   # For Spike


.EQU NS16550_BASE,  0x10000000
.EQU NS16550_IER,   1              // Interrupt Enable Register offset
.EQU UART_IER_THRI, 0x02           // Transmitter Holding Register Interrupt enable

.EQU PLIC_BASE,     0x0c000000
.EQU PLIC_PRIORITY, 0x0c000000     // Priority for interrupt ID 0, used
.EQU PLIC_ENABLE,   0x0c002000     // Enable bits for context 0 (M-mode hart 0)
.EQU PLIC_THRESHOLD,0x0c200000     // Threshold for context 0
.EQU PLIC_CLAIM,    0x0c200004     // Claim/complete for context 0


.global rvtest_entry_point

rvtest_entry_point:
    la sp, topofstack       # Initialize stack pointer
    la s6, begin_signature  # s6 points to signature

    # Set up trap handler
    la t0, trap_handler
    csrw mtvec, t0          # Initialize MTVEC to trap_handler
    csrw mideleg, zero      # Don't delegate interrupts
    csrw medeleg, zero      # Don't delegate exceptions
    la t0, topoftrapstack
    csrw mscratch, t0       # MSCRATCH holds trap stack pointer

    # set up PMP so user and supervisor mode can access full address space
    csrw pmpcfg0, 0xF   # configure PMP0 to TOR RWX
    li t0, 0xFFFFFFFF
    csrw pmpaddr0, t0   # configure PMP0 top of range to 0xFFFFFFFF to allow all 32-bit addresses


    # Configure PLIC for interrupt ID 1 (NS16550)
    li t0, PLIC_BASE
    li t1, 7                # Set priority to 7 (max is based on PLIC_PRIO_BITS)
    sw t1, 4*UART_INT_SRC(t0)            # Set priority for interrupt source (offset from base)

    li t0, PLIC_ENABLE
    li t1, 1<<UART_INT_SRC   # Enable interrupt ID for interrupt source
    sw t1, 0(t0)             # Enable interrupt 1 for context 0

    li t0, PLIC_THRESHOLD
    sw zero, 0(t0)          # Set priority threshold to 0 (accept all priorities)

    # Enable machine external interrupts
    li t0, 0x800            # MIE.MEIE = bit 11
    csrw mie, t0            # Enable machine external interrupt in MIE
    csrsi mstatus, 0x8      # Turn on mstatus.MIE global interrupt enable

main:
    # Change to user mode
    li a0, 0                # a0 = 0: argument to enter user mode
    ecall                   # System call to enter user mode

    # Trigger NS16550 UART transmitter interrupt
    # The UART starts with transmitter empty, so enabling the
    # transmitter interrupt will immediately trigger it
    li t0, NS16550_BASE
    li t1, UART_IER_THRI    # Enable transmitter holding register interrupt
    sb t1, NS16550_IER(t0)  # Write to IER register

    # The interrupt should fire here since UART LSR has TEMT set

    # Wait a bit for interrupt to occur
    li t0, 100
1:  addi t0, t0, -1
    bnez t0, 1b

done:
    li a0, 4                # argument to finish program
    ecall                   # system call to finish program
    j self_loop             # wait forever

.align 4                    # trap handlers must be aligned to multiple of 4
trap_handler:
    # Load trap handler stack pointer tp
    csrrw tp, mscratch, tp  # swap MSCRATCH and tp
    sd t0, 0(tp)            # Save t0 and t1 on the stack
    sd t1, -8(tp)
    csrr t0, mcause         # Check the cause
    csrr t1, mtval          # And the trap value
    sd t0, 0(s6)            # Save MCAUSE and MTVAL in the signature
    sd t1, 8(s6)
    addi s6, s6, 16
    bgez t0, exception      # if msb is clear, it is an exception

interrupt:                  # must be an external interrupt
    # Disable the UART interrupt to prevent it from firing again
    li t0, NS16550_BASE
    sb zero, NS16550_IER(t0)  # Clear IER to disable interrupts

    li t1, PLIC_CLAIM       # address of Claim register
    lw t0, 0(t1)            # read claim register to get the interrupt ID
    # t0 should contain the interrupt source ID
    sw t0, 0(t1)            # write it back to Claim register to complete


    j trap_return           # clean up and return

exception:
    csrr t1, mepc           # add 4 to MEPC to determine return address
    addi t1, t1, 4
    csrw mepc, t1
    li t1, 8                # is it an ecall trap?
    andi t0, t0, 0xFC       # if CAUSE = 8, 9, or 11
    bne t0, t1, trap_return # ignore other exceptions

ecall:
    li t0, 4
    beq a0, t0, write_tohost    # call 4: terminate program
    bltu a0, t0, changeprivilege    # calls 0-3: change privilege level
    j trap_return           # ignore other ecalls

changeprivilege:
    li t0, 0x00001800       # mask off mstatus.MPP in bits 11-12
    csrc mstatus, t0
    andi a0, a0, 0x003      # only keep bottom two bits of argument
    slli a0, a0, 11         # move into mstatus.MPP position
    csrs mstatus, a0        # set mstatus.MPP with desired privilege

trap_return:                # return from trap handler
    ld t1, -8(tp)           # restore t1 and t0
    ld t0, 0(tp)
    csrrw tp, mscratch, tp  # restore tp
    mret                    # return from trap

write_tohost:
    la t1, tohost
    li t0, 1                # 1 for success, 3 for failure
    sd t0, 0(t1)            # send success code

self_loop:
    j self_loop             # wait

.section .tohost
tohost:                     # write to HTIF
    .dword 0
fromhost:
    .dword 0

.EQU XLEN,64
begin_signature:
    .fill 6*(XLEN/32),4,0xdeadbeef
end_signature:

# Initialize stack with room for 512 bytes
.bss
    .space 512
topofstack:
# And another stack for the trap handler
.bss
    .space 512
topoftrapstack:

.section .text.init
.globl rvtest_entry_point

# register to write for GPIO output pins
.equ GPIO_OUTPUT_VAL, 0x1006000C
.equ CLINT_MTIMECMP, 0x02004000
.equ PERIOD, 500

# register use:
# s0: address of GPIO_OUTPUT_VAL
# s1: adress of CLINT_MTIME_CMP
# s2: PERIOD

rvtest_entry_point:
   
    # initialize LED to off
    li s0, GPIO_OUTPUT_VAL
    sw zero, 0(s0)      # LEDs off

    # configure timer interrupt
    li s2, PERIOD       
    csrr t0, time       # read lower 32 bits of timer
    csrr t1, timeh      # read upper 32 bits of timer
    add t0, t0, s2      # increment by PERIOD
    li s1, CLINT_MTIMECMP # set timer for next toggle
    sw t0, 0(s1)        # CLINT_MTIMECMP = time + PERIOD
    sw zero, 4(s1)      # upper word = 0 (this is only because program is just starting)
    # csrci mstatus, 8    # clear mstatus.MIE so interrupts are globally disabled
    li t0, 128          # 1 in mie.MTIE
    csrw mie, t0        # enable timer interrupts
    li s3, 4            # loop counter

/*
    # enter user mode
    li t0, 0b11         # 3
    slli t0, t0, 11     # 11 in bits 12:11
    csrc mstatus, t0    # mstatus.MPP = 00 (for user mode)
    la t0, user_start   # 
    csrw mepc, t0       # where to go when entering user mode
    mret
*/

#user_start:             # loop with wfi
wait_loop:
    csrr t0, time       # check time before timer fires
    wfi                 # wait until timer interrupt fires.
    csrr t0, time       # check time again after timer fires for debugging
    # interrupts are globally disabled, so when the timer fires, 
    # wfi will advance here rather than going to an interrupt handler
    lw t0, 0(s0)        # read GPIO_OUTPUT_VAL
    xori t0, t0, 1      # toggle least significant bits
    sw t0, 0(s0)        # update GPIO_OUTPUT_VAL to turn LED off->on or on->off
    lw t0, 0(s1)        # read CLINT_MTIME_CMP
    add t0, t0, s2      # add PERIOD
    sw t0, 0(s1)        # CLINT_MTIME_CMP = CLINT_MTIME_CMP + PERIOD
    addi s3, s3, -1     # decrement loop counter
    bnez s3, wait_loop  # repeat

self_loop:
    j self_loop


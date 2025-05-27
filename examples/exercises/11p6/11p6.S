.section .text.init
.globl rvtest_entry_point

rvtest_entry_point:

    # set up PMP so all of memory is accessible and we don't trap when entering supervisor mode
    # Define region 0 to cover all addresses as RWX
    nop
    csrw pmpcfg0, 0xF   # configure PMP0 to TOR RWX
    li t0, 0xFFFFFFFF   
    csrw pmpaddr0, t0   # configure PMP0 top of range to 0xFFFFFFFF to allow all 32-bit addresses

    # switch to supervisor mode
    # Set mstatus.MPP to 01, set MPEC to a trampoline address where supervisor should begin, do mret
    la t0, supervisorstart
    csrw mepc, t0           # set address for supervisor code to starting
    li t0, 1                
    slli t1, t0, 11         # 1 in bit 11
    csrs mstatus, t1        
    slli t1, t0, 12         # 1 in bit 12
    csrc mstatus, t1        # change mstatus.MPP to 01 (for supervisor mode)
    mret                    # enter supervisor mode at supervisorstart
    nop

supervisorstart:
    la t0, pagetable        # get address of root page table
    srli t0, t0, 12         # extract PPN of root page table
    li t1, 1
    slli t1, t1, 31         # 1 in bit 31
    or t0, t0, t1           # satp value to enable SV32 with root page table
    csrw satp, t0           # enable virtual memory
    
    # now we are execuiting on virtual page 0x80000, which is also physical page 0x80000
    li t0, 0x90000300       
    li t1, 42
    sw t1, 0(t0)


    la t0, testcode         # address of a routine to run
    lui t1, 0x10000         
    add t0, t0, t1          # address of testcode on virtual page 0x90000 
    jr t0                   # jump to the testcode on Virtual page 0x90000, 
                            #   which still points to same code on physical page 0x80000
    nop                     # shouldn't be executed

testcode:
    li t0, 42                # do something

write_tohost:
    la s1, tohost           # terminate with write tohost
    li t0, 1                # 1 for success, 3 for failure
    sw t0, 0(s1)            # send success code
    sw zero, 4(s1)          # not obvious why Sail isn't terminating unless this write is done

self_loop:
    j self_loop

tohost:
    .word 0

.data


.align 16
# root (L1) Page table situated at 0x80010000
pagetable:
    .space 2048 # skip over addresses below 0x80000000
    .4byte 0x20004401 # VPN1 = 512 (VA = 0x80000000) points to L0 page table at 80011000
    .space 252 # skip over addresses below 0x90000000
    .4byte 0x20004401 # VPN 576 (VA = 0x90000000) points to L0 page table at 0x80011000

.align 12
# L0 page table situated at 0x80011000
    .4byte 0x200000CF # VPN 0 points to physical kilopage at 0x80000000 with Dirty, Access, XWR, Valid  




.equiv CAFE_CAFE, 0xCAFECAFE

.macro call_update_hash
    call update_hash
.endm

.macro pmp_update_hash
    csrw mtvec, a5
    restore_interrupts a3, a4
    call_update_hash
    disable_interrupts a3, a4
    la t0, pmp_trap_handler     # Load handler address
    csrrw a5, mtvec, t0         # Set MTVEC to point to handler
.endm

.altmacro
.macro test_entry reg_cfg:req cfg_index:req reg_address:req
    LOCAL is_not_locked, test_err_l, test_set_l, test_err_cfg_nl, test_set_cfg_nl, test_err_addr_nl, test_set_addr_nl, test_end

    csrr t0, \reg_cfg                   # Load original configuration in t0

    srli t1, t0, 8 * \cfg_index         # Isolate requested byte in t1
    .iflt (\cfg_index - 3)
        andi t1, t1, 0xff
    .endif
    andi t2, t1, 0x80
    beqz t2, is_not_locked

    # Here start locked case
    li t2, 0xff << (\cfg_index << 3)    # Set testing mask
    csrc \reg_cfg, t2                   # Try to clear locked entry
    csrr t1, \reg_cfg                   # Re-read register
    beq t1, t0, test_set_l

test_err_l:
    addi t0, x0, 1
    j test_end

test_set_l:
    csrs \reg_cfg, t2                   # Try to set locked entry
    csrr t1, \reg_cfg                   # Re-read register
    bne t1, t0, test_err_l

    csrr t0, \reg_address               # Load original locked address in t0

    csrw \reg_address, x0               # Try to clear locked address
    csrr t1, \reg_address               # Re-read register
    bne t1, t0, test_err_l

    addi t1, x0, -1
    csrw \reg_address, t1               # Try to set locked address
    csrr t1, \reg_address               # Re-read register
    bne t1, t0, test_err_l
    mv t0, x0
    j test_end

is_not_locked:
    li t2, 0xff << (\cfg_index << 3)    # Set testing mask
    csrc \reg_cfg, t2                   # Try to clear free entry
    csrr t1, \reg_cfg                   # Re-read registry
    srli t1, t1, 8 * \cfg_index         # Isolate requested byte in t1
    .iflt (\cfg_index - 3)
        andi t1, t1, 0xff
    .endif
    beqz t1, test_set_cfg_nl

test_err_cfg_nl:
    addi t0, x0, 1                      # Test failed, set to 1
    csrw \reg_cfg, t0
    j test_end

test_set_cfg_nl:
    li t2, 0x7f << (\cfg_index << 3)    # Set testing mask WITHOUT locking
    csrs \reg_cfg, t2                   # Try to set free entry
    csrr t1, \reg_cfg                   # Re-read registry
    and t1, t1, t2
    bne t1, t2, test_err_cfg_nl

    csrw \reg_cfg, t0                   # Here we can restore configuration reg
    csrr t3, \reg_address               # Save original address

    csrw \reg_address, x0               # Clear free address register
    csrr t2, \reg_address               # Re-read register
    beqz t2, test_set_addr_nl

test_err_addr_nl:
    csrw \reg_address, t3
    addi t0, x0, 1
    j test_end

test_set_addr_nl:
    addi t1, x0, -1
    csrw \reg_address, t1               # Set free address register
    csrr t2, \reg_address               # Re-read register
    bne t2, t1, test_err_addr_nl

    csrw \reg_address, t3               # Restore address and clear error
    mv t0, x0
test_end:
    .ifgt \cfg_index
        slli t0, t0, \cfg_index
    .endif
.endm

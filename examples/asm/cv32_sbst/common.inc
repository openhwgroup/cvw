# Define PROCedure definitions macros
.ifdef DEBUG
.set __is_debug_build, 1
.endif
.ifdef _DEBUG
.set __is_debug_build, 1
.endif
.ifdef __is_debug_build
.warning "Adding debugging informations..."
.endif

.macro PRIVATE_PROC func_name:req
    .p2align 4, 0x00
.ifdef __is_debug_build
    .func \func_name, \func_name
.endif
    .type \func_name, @function
\func_name:
.ifdef __is_debug_build
    .cfi_startproc
.endif
.endm

.macro PROC func_name:req
    .globl \func_name
    PRIVATE_PROC \func_name
.endm

.macro ENDP func_name:req
.ifdef __is_debug_build
    .cfi_endproc
.endif
    .size \func_name, (. - \func_name)
.ifdef __is_debug_build
    .endfunc
.endif
.endm

# Handle interrupts
.macro disable_interrupts old_mie:req old_mstatus:req
    csrrw \old_mie, mie, x0
    csrrci \old_mstatus, mstatus, 0x8
.endm

.macro restore_interrupts old_mie, old_mstatus:req
    csrw mstatus, \old_mstatus
    csrw mie, \old_mie
.endm

# Save/restore registers on stack
.macro accumulate instruction:req dest_reg:req source_regs:vararg
    .irp reg, \source_regs
        \instruction \dest_reg , \dest_reg , \reg
    .endr
.endm

.macro faccumulate instruction:req dest_reg:req source_regs:vararg
    .irp reg, \source_regs
        fmv.x.w t0, \reg
        \instruction \dest_reg , \dest_reg , t0
    .endr
.endm

.altmacro
.macro move_regs op:req instruction:req pointer_reg:req regs:vararg
    .ifnc \op, push
        .ifnc \op, pop
            .error "Wrong parameter: op: Must be push or pop"
        .endif
    .endif
    LOCAL idx, len
    .set idx, 0
    .irp reg, \regs
        .set idx, idx + 4
    .endr
    .set len, idx
    .ifc \op, push
        addi sp, sp, -idx
    .endif
    .set idx, idx - 4
    .irp reg, \regs
        \instruction \reg , idx (\pointer_reg)
        .set idx, idx - 4
    .endr
    .ifc \op, pop
        addi sp, sp, len
    .endif
.endm

.macro count_instructions_start
    csrci mcountinhibit, 4
    csrsi mcounteren, 4
    csrw minstret, x0
.endm

.macro count_instructions dest:req
    csrr \dest , minstret
    addi \dest , \dest , -1
.endm

.macro atpg_init_hash
    lui a0, 0xaa7d
    call init_hash
.endm

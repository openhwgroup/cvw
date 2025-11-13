.macro read_ro csr_code:req dest=a0 write_reg=x0 write_clear=x0 write_set=x0 write_imm=0x20 clear_imm=0x20 set_imm=0x20
    .ifnc \write_reg, x0
        csrrw \dest, \csr_code, \write_reg
        csrw \csr_code, \write_reg
    .endif
    .ifnc \write_clear, x0
        csrc \csr_code, \write_clear
        csrrc \dest, \csr_code, \write_clear
    .endif
    .ifnc \write_set, x0
        csrrs \dest, \csr_code, \write_set
        csrs \csr_code, \write_set
    .endif
    .ifge (0x1f - \write_imm)
        csrwi \csr_code, \write_imm
        csrrwi \dest, \csr_code, \write_imm
    .endif
    .ifge (0x1f - \clear_imm)
        csrrci \dest, \csr_code, \clear_imm
        csrci \csr_code, \clear_imm
    .endif
    .ifge (0x1f - \set_imm)
        csrsi \csr_code, \set_imm
        csrrsi \dest, \csr_code, \set_imm
    .endif
    csrrc \dest, \csr_code, \write_clear
    csrrs \dest, \csr_code, \write_set
    csrrci \dest, \csr_code, 0
    csrrsi \dest, \csr_code, 0
    csrr \dest, \csr_code
.endm

.macro call_update_hash
    jalr a5
.endm

.macro hash_ro csr_code:req dest=a0 write_reg=x0 write_clear=x0 write_set=x0 write_imm=0x20 clear_imm=0x20 set_imm=0x20
    read_ro   \csr_code,   \dest,  \write_reg,  \write_clear,  \write_set,  \write_imm,    \clear_imm,    \set_imm
    .ifnc \dest, a0
        mv a0, \dest
    .endif
    call_update_hash
.endm

.macro init_block csr_code:req
    disable_interrupts t6, a6
    csrr a0, \csr_code
    csrrw t3, \csr_code, t0
    csrrc t4, \csr_code, t2
    csrrs t5, \csr_code, t1
.endm

.macro finalize_block csr_code:req do_hash
    csrw \csr_code, a0
    restore_interrupts t6, a6
    .ifc \do_hash, hash
        mv a0, t0
        call_update_hash
        mv a0, t1
        call_update_hash
        mv a0, t2
        call_update_hash
        mv a0, t3
        call_update_hash
        mv a0, t4
        call_update_hash
        mv a0, t5
        call_update_hash
    .endif
.endm

.macro init_masked_block csr_code:req
    disable_interrupts t6, a6
    csrr a0, \csr_code
    csrrc t2, \csr_code, t0
    csrrs t3, \csr_code, t1
.endm

.macro finalize_masked_block csr_code:req do_hash
    csrw \csr_code, a0
    restore_interrupts t6, a6
    .ifc \do_hash, hash
        mv a0, t0
        call_update_hash
        mv a0, t1
        call_update_hash
        mv a0, t2
        call_update_hash
        mv a0, t3
        call_update_hash
    .endif
.endm

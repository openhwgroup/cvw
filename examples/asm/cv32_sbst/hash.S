.file "hash.S"
.title "STL hash code"

.option nopic
.option rvc
.option relax

.include "common.inc"

.macro process_chunk block=a0
    C.add a1, \block
    slli a0, a1, 3
    C.add a1, a0
    C.add a2, a1
    slli a0, a2, 7
    C.srli a2, 25
    C.or a2, a0
    slli a0, a2, 2
    C.add a2, a0
.endm


.text

# void update_hash(uint32_t block);
# Uses t0
PROC update_hash
    mv t0, a0
    andi a0, a0, 0xFF
    process_chunk
    slli a0, t0, 16
    C.srli a0, 24
    process_chunk
    slli a0, t0, 8
    C.srli a0, 24
    process_chunk
    srli a0, t0, 24
    process_chunk
    ret
ENDP update_hash

# void init_hash(uint32_t seed);
PROC init_hash
    li a1, 0x5582
    C.xor a1, a0
    slli a2, a0, 15
    C.srli a0, 17
    C.or a2, a0
    ret
ENDP init_hash

# uint32_t finalize_hash();
# Uses a3
PROC finalize_hash
    C.xor a1, a2
    slli a0, a2, 14
    srli a3, a2, 18
    C.or a0, a3
    C.add a1, a0
    C.xor a2, a1
    srli a0, a2, 6
    slli a3, a2, 26
    C.or a0, a3
    C.add a2, a0
    C.xor a1, a2
    slli a0, a2, 5
    srli a3, a2, 27
    C.or a0, a3
    C.add a1, a0
    C.xor a2, a1
    srli a0, a2, 8
    slli a3, a2, 24
    C.or a0, a3
    C.add a0, a2
    ret
ENDP finalize_hash

# void fast_hash(uint32_t block);
PROC fast_hash
    process_chunk
    ret
ENDP fast_hash

.end

.section .text
.global _start


.section .text
.globl _start

_start:
    #--------------------------------------------------------
    # Load plaintext into state (a4–a7)
    la a0, plaintext
    lw a4, 0(a0)
    lw a5, 4(a0)
    lw a6, 8(a0)
    lw a7, 12(a0)

    # Load 128-bit key (s0–s3)
    la a1, key
    lw s0, 0(a1)
    lw s1, 4(a1)
    lw s2, 8(a1)
    lw s3, 12(a1)

    #--------------------------------------------------------
    # Round 0: AddRoundKey
    xor a4, a4, s0
    xor a5, a5, s1
    xor a6, a6, s2
    xor a7, a7, s3

    #--------------------------------------------------------
    # AES Key Schedule (compute 10 round keys)
    la a2, round_keys
    sw s0, 0(a2)
    sw s1, 4(a2)
    sw s2, 8(a2)
    sw s3, 12(a2)

    li t0, 1          # rcon
    li t1, 1          # round counter (1–10)
    addi a2, a2, 16   # point to next key slot

key_expansion_loop:
    # RotWord + SubWord
    slli t2, s3, 8         # rotate left by 1 byte
    srli t3, s3, 24
    or t2, t2, t3
    aes32esi t2, zero, t2, 0

    # XOR with rcon in top byte
    li t3, 0x01000000
    mul t3, t0, t3
    xor t2, t2, t3

    # w0 = w0 ⊕ t2
    xor s0, s0, t2
    xor s1, s1, s0
    xor s2, s2, s1
    xor s3, s3, s2

    sw s0, 0(a2)
    sw s1, 4(a2)
    sw s2, 8(a2)
    sw s3, 12(a2)
    addi a2, a2, 16

    addi t1, t1, 1
    slli t0, t0, 1     # rcon <<= 1
    li t3, 0x11b
    blt t0, t3, no_reduce
    xor t0, t0, t3
no_reduce:

    li t2, 11
    blt t1, t2, key_expansion_loop

    # AES Rounds (rounds 1–9)
    li t1, 1
    la a3, round_keys
    addi a3, a3, 16
    li s10, 10
	
aes_enc_loop:
    bge t1, s10, final_round

    aes32esmi t0, zero, a4, 0
    aes32esmi t0, t0, a5, 1
    aes32esmi t0, t0, a6, 2
    aes32esmi t0, t0, a7, 3

    aes32esmi t1, zero, a5, 0
    aes32esmi t1, t1, a6, 1
    aes32esmi t1, t1, a7, 2
    aes32esmi t1, t1, a4, 3

    aes32esmi t2, zero, a6, 0
    aes32esmi t2, t2, a7, 1
    aes32esmi t2, t2, a4, 2
    aes32esmi t2, t2, a5, 3

    aes32esmi t3, zero, a7, 0
    aes32esmi t3, t3, a4, 1
    aes32esmi t3, t3, a5, 2
    aes32esmi t3, t3, a6, 3

    lw s0, 0(a3)
    lw s1, 4(a3)
    lw s2, 8(a3)
    lw s3, 12(a3)

    xor a4, t0, s0
    xor a5, t1, s1
    xor a6, t2, s2
    xor a7, t3, s3

    addi a3, a3, 16
    addi t1, t1, 1
    j aes_enc_loop

# Final round: aes32esi + AddRoundKey
final_round:
    aes32esi t0, zero, a4, 0
    aes32esi t0, t0, a5, 1
    aes32esi t0, t0, a6, 2
    aes32esi t0, t0, a7, 3

    aes32esi t1, zero, a5, 0
    aes32esi t1, t1, a6, 1
    aes32esi t1, t1, a7, 2
    aes32esi t1, t1, a4, 3

    aes32esi t2, zero, a6, 0
    aes32esi t2, t2, a7, 1
    aes32esi t2, t2, a4, 2
    aes32esi t2, t2, a5, 3

    aes32esi t3, zero, a7, 0
    aes32esi t3, t3, a4, 1
    aes32esi t3, t3, a5, 2
    aes32esi t3, t3, a6, 3

    lw s0, 0(a3)
    lw s1, 4(a3)
    lw s2, 8(a3)
    lw s3, 12(a3)

    xor a4, t0, s0
    xor a5, t1, s1
    xor a6, t2, s2
    xor a7, t3, s3

    la a0, ciphertext
    sw a4, 0(a0)
    sw a5, 4(a0)
    sw a6, 8(a0)
    sw a7, 12(a0)

# Finalize
done:
    mv a0, a4              # Return first word of ciphertext
    andi a0, a0, 0xFF      # Mask to 8 bits
    csrr s9, instret       # Read instruction count
    # Note: If you want to calculate instructions executed, you need to
    # save the initial instret value and subtract it here.

write_tohost:
    la t1, tohost
    li t0, 1               # Success code
    sw t0, 0(t1)           # Send success code

self_loop:
    j self_loop

.section .tohost
tohost:
    .word 0
fromhost:
    .word 0



.data
.align 4

.EQU XLEN,32
begin_signature:
    .fill 4*12*(XLEN/32),4,0xdeadbeef
end_signature:

.section .data
.align 4

plaintext:
    .word 0x3243f6a8, 0x885a308d, 0x313198a2, 0xe0370734

key:
    .word 0x2b7e1516, 0x28aed2a6, 0xabf71588, 0x09cf4f3c

round_keys:
    .space 176

ciphertext:
    .space 16

.bss
    .space 512



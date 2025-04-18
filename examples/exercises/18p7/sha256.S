.section .text
.global _start

_start:
    # Load initial hash state into a0–a7
    la t0, H
    lw a0, 0(t0)
    lw a1, 4(t0)
    lw a2, 8(t0)
    lw a3, 12(t0)
    lw a4, 16(t0)
    lw a5, 20(t0)
    lw a6, 24(t0)
    lw a7, 28(t0)

    # Store initial state in signature
    la s11, begin_signature
    sw a0, 0(s11)	
    sw a1, 4(s11)
    sw a2, 8(s11)
    sw a3, 12(s11)
    sw a4, 16(s11)	
    sw a5, 20(s11)
    sw a6, 24(s11)
    sw a7, 28(s11)	
    addi s11, s11, 32
    csrr s8, instret   				# count instructions at beginning
	
    # Load padded message into W[0..15]
    la s0, M
    la s1, W
    li t1, 0

load_loop:
    lw t2, 0(s0)
    sw t2, 0(s1)
    addi s0, s0, 4
    addi s1, s1, 4
    addi t1, t1, 1
    li t3, 16
    blt t1, t3, load_loop

    # Compute W[16..63]
    la s1, W
    li t1, 16

gen_loop:
    slli t2, t1, 2
    add t3, s1, t2

    lw t4, -8(t3)
    lw t5, -28(t3)
    lw t6, -60(t3)
    lw t0, -64(t3)

    sha256sig1 t4, t4
    sha256sig0 t6, t6

    add t4, t4, t5
    add t4, t4, t6
    add t4, t4, t0

    sw t4, 0(t3)

    addi t1, t1, 1
    li t5, 64
    blt t1, t5, gen_loop

    # Working vars: s2–s9 = a-h
    mv s2, a0
    mv s3, a1
    mv s4, a2
    mv s5, a3
    mv s6, a4
    mv s7, a5
    mv s8, a6
    mv s9, a7

    li t0, 0           				# round counter
    la t1, K
    la t2, W

# Compression Function
# T1 = SUM1(e) + Ch(e,f,g) + K[i] + W[i]
# T2 = SUM0(a) + Maj(a,b,c)
	
sha_round:
    slli t3, t0, 2
    add t4, t1, t3
    lw t5, 0(t4)       				# K[t]

    add t4, t2, t3
    lw t6, 0(t4)       				# W[t]

    sha256sum1 a0, s6
    xor a1, s6, s7
    and a1, a1, s8
    xor a1, a1, s7     				# Ch

    add a2, a0, a1
    add a2, a2, t5
    add a2, a2, t6     				# T1

    sha256sum0 a3, s2
    xor a4, s2, s3
    and a4, a4, s4
    xor a4, a4, s3     				# Maj

    add a5, a3, a4     				# T2

    # Rotate working vars
    mv a6, s9
    mv s9, s8
    mv s8, s7
    mv s7, s6
    add s6, s5, a2
    mv s5, s4
    mv s4, s3
    mv s3, s2
    add s2, a2, a5

    addi t0, t0, 1
    li a7, 64
    blt t0, a7, sha_round

    # Add to original hash values
    add a0, a0, s2
    add a1, a1, s3
    add a2, a2, s4
    add a3, a3, s5
    add a4, a4, s6
    add a5, a5, s7
    add a6, a6, s8
    add a7, a7, s9

    # Store result in signature
    sw a0, 0(s11)	
    sw a1, 4(s11)
    sw a2, 8(s11)
    sw a3, 12(s11)
    sw a4, 16(s11)	
    sw a5, 20(s11)
    sw a6, 24(s11)
    sw a7, 28(s11)	
    addi s11, s11, 32
	
# Finalize
done:
    csrr s9, instret       			# Read instruction count
    sub s9, s9, s8	        		# get number of #instructions executed	
    sw s9, 0(s11)	
	
write_tohost:
    la t1, tohost
    li t0, 1               			# Success code
    sw t0, 0(t1)           			# Send success code

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
    .fill (8*2+5)*(XLEN/32),4,0xdeadbeef
end_signature:

# Initial SHA-256 hash values
H:
    .word 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
    .word 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

# K constants for SHA-256
K:
    .word 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5
    .word 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
    .word 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3
    .word 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174
    .word 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc
    .word 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da
    .word 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7
    .word 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967
    .word 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13
    .word 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85
    .word 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3
    .word 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070
    .word 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5
    .word 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3
    .word 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208
    .word 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

# One padded 512-bit block for message "Go Wally!"
M:
    .word 0x476f2057, 0x616c6c79, 0x21800000, 0x00000000
    .word 0x00000000, 0x00000000, 0x00000000, 0x00000000
    .word 0x00000000, 0x00000000, 0x00000000, 0x00000000
    .word 0x00000000, 0x00000000, 0x00000000, 0x00000048

# Space for W[0..63] (64 x 4 bytes)	
W:
     .skip 256   


.bss
    .space 512

	

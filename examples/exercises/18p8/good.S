.section .text
.global _start

# Elaborated routines based on https://github.com/riscv/riscv-crypto	
_start:
    # Store initial state in signature
    la s11, begin_signature

    csrr s8, instret				# count instructions at beginning


# Finalize
done:
    csrr s9, instret       			# Read instruction count
    sub s9, s9, s8	        		# get number of #instructions executed	
    sw s9, 0(s11)	
	
write_tohost:
    la a0, tohost
    li a1, 1               			# Success code
    sd a1, 0(a0)           			# Send success code

self_loop:
    j self_loop

.section .tohost
tohost:
    .dword 0
fromhost:
    .dword 0

.data
.align 4

.EQU XLEN,64
begin_signature:
    .fill (4+1)*(XLEN/32),4,0xdeadbeef
end_signature:

# FIPS 197 Example Appendix A AES-128 (stored little endian)
plaintext:
    .word 0xa8f64332, 0x8d305a88, 0xa2983131, 0x340737e0

# Key Expansion Example Appendix B AES-128
key_schedule:
    .word 0x16157e2b, 0xa6d2ae28, 0x8815f7ab, 0x3c4fcf09  # Round 0
    .word 0x17fefaa0, 0xb12c5488, 0x3939a323, 0x05766c2a  # Round 1
    .word 0xf295c2f2, 0x43b9967a, 0x7a803559, 0x7ff65973  # Round 2
    .word 0x7d47803d, 0x3efe1647, 0x447e231e, 0x3b887a6d  # Round 3
    .word 0x41a544ef, 0x7f5b52a8, 0x3b2571b6, 0x00ad0bdb  # Round 4
    .word 0xf8c6d1d4, 0x879d837c, 0xbcb8f2ca, 0xbc15f911  # Round 5
    .word 0x7aa3886d, 0xfd3e0b11, 0x4186f9db, 0xfd9300ca  # Round 6
    .word 0x0ef7544e, 0xf3c95f5f, 0xb24fa684, 0x4fdca64e  # Round 7
    .word 0x2173d2ea, 0xd2ba8db5, 0x60f52b31, 0x2f298d7f  # Round 8
    .word 0xf36677ac, 0x21dcfa19, 0x4129d128, 0x6e005c57  # Round 9
    .word 0xa8f914d0, 0x8925eec9, 0xc80c3fe1, 0xa60c63b6  # Round 10

ciphertext:
    .space 16

.bss
    .space 512


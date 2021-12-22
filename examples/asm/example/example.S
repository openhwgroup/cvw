// example.s
// David_Harris@hmc.edu 5 December 2021

.section .text.init
//.globl rvtest_entry_point
//rvtest_entry_point:

.globl main
main:
    li a0, 42

self_loop:
    j self_loop

.end

/*
#include "model_test.h"
#include "arch_test.h"
RVTEST_ISA("RV32I")

.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

#ifdef TEST_CASE_1

RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True;",add)

RVTEST_SIGBASE( x3,signature_x3_1)

inst_0:
// rs2 == rd != rs1, rs1==x4, rs2==x24, rd==x24, rs1_val > 0 and rs2_val > 0, rs2_val == 1, rs1_val == (2**(xlen-1)-1), rs1_val != rs2_val, rs1_val == 2147483647
// opcode: add ; op1:x4; op2:x24; dest:x24; op1val:0x7fffffff;  op2val:0x1
TEST_RR_OP(add, x24, x4, x24, 0x80000000, 0x7fffffff, 0x1, x3, 0, x18)


80000000 <rvtest_entry_point>:

.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN
80000000:	feedc0b7          	lui	ra,0xfeedc
8

80003220 <rvtest_code_end>:
#endif


RVTEST_CODE_END
RVMODEL_HALT
80003220:	00408093          	addi	ra,ra,4
80003224:	00100093          	li	ra,1

80003228 <write_tohost>:
80003228:	00001f17          	auipc	t5,0x1
8000322c:	dc1f2c23          	sw	ra,-552(t5) # 80004000 <tohost>

80003230 <self_loop>:
80003230:	0000006f          	j	80003230 <self_loop>
80003234:	0000                	unimp
	...
*/
#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H

#define RVMODEL_DATA_SECTION \
        .pushsection .tohost,"aw",@progbits;                            \
        .align 8; .global tohost; tohost: .dword 0;                     \
        .align 8; .global fromhost; fromhost: .dword 0;                 \
        .popsection;                                                    \
        .align 8; .global begin_regstate; begin_regstate:               \
        .word 128;                                                      \
        .align 8; .global end_regstate; end_regstate:                   \
        .word 4;

//RV_COMPLIANCE_HALT
#define RVMODEL_HALT                                              \
  li x1, 1;                                                                   \
  write_tohost:                                                               \
    sw x1, tohost, t0;                                                        \
    j write_tohost;

#define RVMODEL_BOOT

//RV_COMPLIANCE_DATA_BEGIN
#define RVMODEL_DATA_BEGIN                                              \
  RVMODEL_DATA_SECTION                                                        \
  .align 4;\
  .global begin_signature; begin_signature:

//RV_COMPLIANCE_DATA_END
#define RVMODEL_DATA_END                                                      \
  .align 4;\
  .global end_signature; end_signature:  

//RVTEST_IO_INIT
#define RVMODEL_IO_INIT
//RVTEST_IO_WRITE_STR
#define RVMODEL_IO_WRITE_STR(_R, _STR)
//RVTEST_IO_CHECK
#define RVMODEL_IO_CHECK()
//RVTEST_IO_ASSERT_GPR_EQ
#define RVMODEL_IO_ASSERT_GPR_EQ(_S, _R, _I)
//RVTEST_IO_ASSERT_SFPR_EQ
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I)
//RVTEST_IO_ASSERT_DFPR_EQ
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I)

#define ACCESS_FAULT_ADDRESS 0
#define CLINT_BASE_ADDR 0x02000000
#define PLIC_BASE_ADDR 0x0C000000
#define GPIO_BASE_ADDR 0x10060000

#define MTIME           (CLINT_BASE_ADDR + 0xBFF8)
#define MSIP            (CLINT_BASE_ADDR)
#define MTIMECMP        (CLINT_BASE_ADDR + 0x4000)
#define MTIMECMPH       (CLINT_BASE_ADDR + 0x4004)

#define THRESHOLD_0     (PLIC_BASE_ADDR + 0x200000)
#define THRESHOLD_1     (PLIC_BASE_ADDR + 0x201000)
#define INT_PRIORITY_3  (PLIC_BASE_ADDR + 0x00000C)
#define INT_EN_00       (PLIC_BASE_ADDR + 0x002000)
#define INT_EN_10       (PLIC_BASE_ADDR + 0x002080)

#define GPIO_OUTPUT_EN  (GPIO_BASE_ADDR + 0x08)
#define GPIO_OUTPUT_VAL (GPIO_BASE_ADDR + 0x0C)

#define RVMODEL_SET_MSW_INT       \
 li t1, 1;                         \
 li t2, 0x2000000;                 \
 sw t1, 0(t2);

#define RVMODEL_CLEAR_MSW_INT     \
 li t2, 0x2000000;                 \
 sw x0, 0(t2);

#define RVMODEL_CLEAR_MTIMER_INT \
 li t0, -1; \
 la t2, MTIMECMP; \
 SREG t0, 0(t2); \
 #ifdef __riscv_xlen \
     #if __riscv_xlen == 32 \
         sw t0, 4(t2); \
     #endif \
 #else \
     ERROR: __riscv_xlen not defined; \
 #endif

#define RVMODEL_CLEAR_MEXT_INT \
la t0, THRESHOLD_0; \
li t2, 7; \
sw t2, 0(t0); \
la t0, THRESHOLD_1; \
li t2, 7; \
sw t2, 0(t0); \
la t0, INT_PRIORITY_3; \
sw zero, 0(t0); \
la t0, INT_EN_00; \
sw zero, 0(t0); \
la t0, GPIO_BASE_ADDR; \
sw zero, 0x18(t0); \
sw zero, 0x20(t0); \
sw zero, 0x28(t0); \
sw zero, 0x30(t0);

#define RVMODEL_CLR_MSW_INT \
la t0, MSIP; \
lw t2, 0(t0); \
andi t2, t2, -2; \
sw t2, 0(t0);

#define RVMODEL_CLR_MTIMER_INT \
li t0, -1; \
la t2, MTIMECMP; \
SREG t0, 0(t2); \
#ifdef __riscv_xlen \
    #if __riscv_xlen == 32 \
        sw t0, 4(t2); \
    #endif \
#else \
    ERROR: __riscv_xlen not defined; \
#endif

#define RVMODEL_CLR_MEXT_INT \
la t0, THRESHOLD_0; \
li t2, 7; \
sw t2, 0(t0); \
la t0, THRESHOLD_1; \
li t2, 7; \
sw t2, 0(t0); \
la t0, INT_PRIORITY_3; \
sw zero, 0(t0); \
la t0, INT_EN_00; \
sw zero, 0(t0); \
la t0, GPIO_BASE_ADDR; \
sw zero, 0x18(t0); \
sw zero, 0x20(t0); \
sw zero, 0x28(t0); \
sw zero, 0x30(t0);

#define RVMODEL_SET_SSW_INT
#define RVMODEL_CLR_SSW_INT

#define RVMODEL_MCLR_SSW_INT \
csrrci t6, mip, 2; 

#define RVMODEL_SCLR_SSW_INT \
csrrci t6, sip, 2; 

#define RVMODEL_CLR_STIMER_INT

#define RVMODEL_MCLR_STIMER_INT \
li t0, 32; \
csrrc t6, mip, t0;

#define RVMODEL_SCLR_STIMER_INT

#define RVMODEL_CLR_SEXT_INT \
la t0, THRESHOLD_0; \
li t2, 7; \
sw t2, 0(t0); \
la t0, THRESHOLD_1; \
li t2, 7; \
sw t2, 0(t0); \
la t0, INT_PRIORITY_3; \
sw zero, 0(t0); \
la t0, INT_EN_00; \
sw zero, 0(t0); \
la t0, GPIO_BASE_ADDR; \
sw zero, 0x18(t0); \
sw zero, 0x20(t0); \
sw zero, 0x28(t0); \
sw zero, 0x30(t0);

#define RVMODEL_SET_VSW_INT
#define RVMODEL_CLR_VSW_INT
#define RVMODEL_CLR_VTIMER_INT
#define RVMODEL_CLR_VEXT_INT


#endif // _COMPLIANCE_MODEL_H

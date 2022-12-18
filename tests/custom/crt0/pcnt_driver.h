#ifndef __PCNT_DRIVER_H
#define __PCNT_DRIVER_H

long int readPerfCnt(long int cntNum, int clear);
void enablePerfCnt(long int flags);
void disablePerfCnt(long int flags);

#define CYCLE_COUNT (0)
#define INSTR_COUNT (2)
#define LOAD_STAL_COUNT (3)
#define BP_WRONG_DIR_COUNT (4)
#define BR_DIR_COUNT (5)
#define BTB_WRONG_COUNT (6)
#define NON_BR_CFI_COUNT (7)
#define RAS_WRONG_COUNT (8)
#define RETURN_COUNT (9)
#define BTB_CLASS_WRONG_COUNT (10)

#define CYCLE_COUNT_EN (1)
#define INSTR_COUNT_EN (1 << 2)
#define LOAD_STAL_COUNT_EN (1 << 3)
#define BP_WRONG_DIR_COUNT_EN (1 << 4)
#define BR_DIR_COUNT_EN (1 << 5)
#define BTB_WRONG_COUNT_EN (1 << 6)
#define NON_BR_CFI_COUNT_EN (1 << 7)
#define RAS_WRONG_COUNT_EN (1 << 8)
#define RETURN_COUNT_EN (1 << 9)
#define BTB_CLASS_WRONG_COUNT_EN (1 << 10)

#endif

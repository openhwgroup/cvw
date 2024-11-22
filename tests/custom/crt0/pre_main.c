#include <stdlib.h>

#include "pcnt_driver.h"

extern int main(int argc, char *argv[]);

int pre_main(int argc, char *argv[]) {
  long int bpmp0, brcnt0, bpmp1, brcnt1;
  long int bpmp_diff, brcnt_diff;
  bpmp0 = readPerfCnt(BP_WRONG_DIR_COUNT, 0);
  brcnt0 = readPerfCnt(BR_DIR_COUNT, 0);

  // enable counters
  enablePerfCnt(BP_WRONG_DIR_COUNT_EN | BR_DIR_COUNT_EN);

  int res =  main(argc, argv);

  disablePerfCnt(BP_WRONG_DIR_COUNT_EN | BR_DIR_COUNT_EN);

  bpmp1 = readPerfCnt(BP_WRONG_DIR_COUNT, 0);
  brcnt1 = readPerfCnt(BR_DIR_COUNT, 0);
  bpmp_diff = bpmp1 - bpmp0;
  brcnt_diff = brcnt1 - brcnt0;
  
  return res;
}

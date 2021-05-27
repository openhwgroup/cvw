#include "header.h"

int main(){
  //int res = icache_spill_test();
  global_hist_test();
  int res = 1;
  if (res < 0) {
    fail();
    return 0;
  }else {
    if((res = lbu_test()) < 0) {
      fail();
      return 0;
    }
    res = simple_csrbr_test();
    return 0;
  }
}

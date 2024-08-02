#include "time.h"
#include "boot.h"
#include "riscv.h"
#include "uart.h"

float getTime() {
  set_status_fs();
  float numCycles = (float)read_mcycle();
  float ret = numCycles/SYSTEMCLOCK;
  // clear_status_fs();
  return ret;
}

void print_time() {
  print_uart("[");
  set_status_fs();
  print_uart_float(getTime(),5);
  clear_status_fs();
  print_uart("] ");
}

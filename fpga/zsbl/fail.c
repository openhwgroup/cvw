#include "fail.h"
#include "uart.h"
#include "riscv.h"
#include "time.h"

void fail() {
  // Get address that led to failure
  register uint64_t addr;
  asm volatile ("mv %0, ra" : "=r"(addr) : : "memory"); 

  // Print message
  print_time();
  println_with_addr("Failed at: 0x", addr);
  
  // Loop forever
  while(1) {

  }
}

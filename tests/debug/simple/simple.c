
int main() {

  // This is just random simple instructions
  // to test the RISC-V debug gdb
  asm("li a0, 0x1000");
  asm("addi a1, a0, 0x100");
  asm("addi a2, a1, 0x200");
  asm("li a3, 0x4000000");
  asm("sw a0, 0(a3)");
  asm("sw a1, 4(a3)");
  asm("lw a4, 0(a3)");
  asm("lw a5, 4(a3)");
  asm("lw a5, 4(a3)");
  asm("nop");
  while(1);

}

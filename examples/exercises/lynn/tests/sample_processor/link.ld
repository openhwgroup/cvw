OUTPUT_ARCH( "riscv" )
ENTRY(rvtest_entry_point)

SECTIONS
{
  /* Instruction Memory */
  . = 0x80000000;
  .text : { *(.text.init) *(.text) }
  . = ALIGN(0x1000);
  .text : { *(.text.main) }

  /* Data Memory */
  . = ALIGN(0x1000);
  dmem_base = .;
  .rodata : { *(.rodata .rodata.*) *(.srodata .srodata.*) }
  . = ALIGN(16);
  .data : { *(.data) }
  .data.string : { *(.data.string)}
  . = ALIGN(0x1000);
  .tohost : { *(.tohost) }
  . = ALIGN(0x1000);
  .bss : { *(.bss) }
  . = ALIGN(16);
  _stack_bottom = .;
  . += 0x1000;
  _stack_top = .;
  _end = .;
}

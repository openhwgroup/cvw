OUTPUT_ARCH( "riscv" )
ENTRY(rvtest_entry_point)

SECTIONS
{
  /* Instruction Memory */
  . = 0x80000000;
  .text : { *(.text.init) *(.text) }
  . = ALIGN(0x1000);
  .text : { *(.text.main) }
  . = ALIGN(0x1000);
  .tohost : { *(.tohost) }

  /* Data Memory */
  . = 0x80010000;
  .data : { *(.data) }
  .data.string : { *(.data.string)}
  . = ALIGN(0x1000);
  .bss : { *(.bss) }
  . = ALIGN(16);              /* ABI-friendly alignment */
  _stack_bottom = .;
  . += 0x4000;                /* 16 KiB stack (change as you like) */
  _stack_top = .;            /* set sp = __stack_top */
  _end = .;
}

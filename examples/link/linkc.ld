OUTPUT_ARCH( "riscv" )
ENTRY(main)

SECTIONS
{
  . = 0x80000000;
  .text : { *(.text) }
  . = ALIGN(0x1000);
  .tohost : { *(.tohost) }
  . = ALIGN(0x1000);
  .data : { *(.data) }
  .data.string : { *(.data.string)}
  . = ALIGN(0x1000);
  .bss : { *(.bss) }
  _end = .;
}


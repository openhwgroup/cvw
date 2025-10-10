OUTPUT_ARCH( "riscv" )
ENTRY(rvtest_entry_point)

/* Program headers: put code in a RX PT_LOAD and writable objects in an RW PT_LOAD */
PHDRS
{
  /* PF_R | PF_X = 5, PF_R | PF_W = 6 */
  text PT_LOAD FLAGS(5);
  data PT_LOAD FLAGS(6);
}

SECTIONS
{
  /* Place the program at the machine start address */
  . = 0x80000000;

  /* Align to page and place executable/code+rodata in the text PT_LOAD (RX) */
  . = ALIGN(0x1000);
  .text :
  {
    *(.text.init)
    *(.text)
    *(.rodata)
  } :text

  /* I/O/host communications - keep small alignment but put into data PT_LOAD */
  . = ALIGN(0x1000);
  .tohost :
  {
    *(.tohost)
  } :data

  /* Writable data segment */
  . = ALIGN(0x1000);
  .data :
  {
    *(.data)
    *(.data.*)
    . = ALIGN(8);
    *(.data.string)
  } :data

  /* BSS should not occupy file space (NOLOAD) but must be in the RW segment */
  . = ALIGN(0x1000);
  .bss (NOLOAD) :
  {
    *(.bss)
    *(COMMON)
  } :data

  _end = .;
}

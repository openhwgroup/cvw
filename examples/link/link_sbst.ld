/*======================================================================*/
/* Proxy kernel linker script                                           */
/*======================================================================*/
/* This is the linker script used when building the proxy kernel. */

/*----------------------------------------------------------------------*/
/* Setup                                                                */
/*----------------------------------------------------------------------*/

/* The OUTPUT_ARCH command specifies the machine architecture where the
   argument is one of the names used in the BFD library. More
   specifically one of the entries in bfd/cpu-mips.c */

OUTPUT_ARCH( "riscv" )
ENTRY(_start)


__stack_size = 0x00400;
/*----------------------------------------------------------------------*/
/* Sections                                                             */
/*----------------------------------------------------------------------*/

SECTIONS
{

  /* text: test code section */
  . = 0x80000000;
  .text.init : { *(.text.init) }

  . = ALIGN(0x1000);
  .tohost : { *(.tohost) }

  /* interrupt vectors */
  .vectors :
  {
    PROVIDE(__vector_start = .);
    KEEP(*(.vectors));
  } 


  .text : { *(.text) }

  /* data segment */
  .data : { *(.data) }

  .sdata : {
    __global_pointer$ = . + 0x800;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  }

  /* bss segment */
  .sbss : {
    PROVIDE(__bss_start = . );
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
  }
  .bss : { *(.bss) 
  PROVIDE(__bss_end = . );
  }


  /* stack: we should consider putting this further to the top of the address
    space */
  .stack         : ALIGN(16) /* this is a requirement of the ABI(?) */
  {
   PROVIDE(__stack_start = .);
   . = __stack_size;
   PROVIDE(_sp = .);
   PROVIDE(__stack_end = .);
  } 

  /* thread-local data segment */
  .tdata :
  {
    _tls_data = .;
    *(.tdata.begin)
    *(.tdata)
    *(.tdata.end)
  }
  .tbss :
  {
    *(.tbss)
    *(.tbss.end)
  }

  /* End of uninitialized data segment */
  _end = .;
}

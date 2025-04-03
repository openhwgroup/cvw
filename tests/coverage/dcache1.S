      #include "WALLY-init-lib.h"
main:
      // start way test #1
      li t0, 0x80100000
.align 6
      // i$ boundary, way test #1
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      sd zero, 0(t0)
      sd zero, 0(t0)
      .word 0x00000013
      .word 0x00000013
      // start way test #2
      li t0, 0x80101000
.align 6
      // i$ boundary, way test #2
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      sd zero, 0(t0)
      sd zero, 0(t0)
      .word 0x00000013
      .word 0x00000013
      // start way test #3
      li t0, 0x80102000
.align 6
      // i$ boundary, way test #3
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      sd zero, 0(t0)
      sd zero, 0(t0)
      .word 0x00000013
      .word 0x00000013
      // start way test #4
      li t0, 0x80103000
.align 6
      // i$ boundary, way test #4
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      .word 0x00000013
      sd zero, 0(t0)
      sd zero, 0(t0)
      .word 0x00000013
      .word 0x00000013

# test flushing
      li t0, 0x80100000
      cbo.flush (t0)
      li t0, 0x80101000
      cbo.flush (t0)
      li t0, 0x80102000
      cbo.flush (t0)
      li t0, 0x80103000
      cbo.flush (t0)

      j done

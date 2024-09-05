#ifndef __system_H
#define __system_H

#ifndef SYSTEMCLOCK
#define SYSTEMCLOCK  100000000
#endif

#ifndef MAXSDCCLOCK
#define MAXSDCCLOCK  5000000
#endif

#ifndef EXT_MEM_BASE
#define EXT_MEM_BASE 0x80000000
#endif

#ifndef EXT_MEM_RANGE
#define EXT_MEM_RANGE  0x10000000
#endif

#define EXT_MEM_END (EXT_MEM_BASE + EXT_MEM_RANGE)
#define FDT_ADDRESS (EXT_MEM_END - 0x1000000)

#endif

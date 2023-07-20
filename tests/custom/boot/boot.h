#ifndef WALLYBOOT
#define WALLYBOOT 10000

#include <stdint.h>
typedef unsigned int    UINT;   /* int must be 16-bit or 32-bit */
typedef unsigned char   BYTE;   /* char must be 8-bit */
typedef uint16_t        WORD;   /* 16-bit unsigned integer */
typedef uint32_t        DWORD;  /* 32-bit unsigned integer */
typedef uint64_t        QWORD;  /* 64-bit unsigned integer */
typedef WORD            WCHAR;

typedef QWORD LBA_t;

// Define memory locations of boot images =====================
// These locations are copied from the generic configuration
// of OpenSBI. These addresses can be found in:
// buildroot/output/build/opensbi-0.9/platform/generic/config.mk
#define FDT_ADDRESS 0x87000000          // FW_JUMP_FDT_ADDR
#define OPENSBI_ADDRESS 0x80000000      // FW_TEXT_START
#define KERNEL_ADDRESS 0x80200000       // FW_JUMP_ADDR

// Export disk_read
int disk_read(BYTE * buf, LBA_t sector, UINT count, BYTE card_type);

#endif // WALLYBOOT


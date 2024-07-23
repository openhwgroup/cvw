#include <stddef.h>
#include "boot.h"
#include "gpt.h"
#include "uart.h"
#include "spi.h"
#include "sd.h"

/* int disk_read(BYTE * buf, LBA_t sector, UINT count, BYTE card_type) { */

/*   /\* This is not needed. This has everything to do with the FAT */
/*      filesystem stuff that I'm not including. All I need to do is */
/*      initialize the SD card and read from it. Anything in here that is */
/*      checking for potential errors, I'm going to have to temporarily */
/*      do without. */
/*    *\/ */
/*   // if (!count) return RES_PARERR; */
/*     /\* if (drv_status & STA_NOINIT) return RES_NOTRDY; *\/ */

/*   uint32_t response[4]; */
/*   struct sdc_regs * regs = (struct sdc_regs *)SDC; */
  
/*     /\* Convert LBA to byte address if needed *\/ */
/*     if (!(card_type & CT_BLOCK)) sector *= 512; */
/*     while (count > 0) { */
/*         UINT bcnt = count > MAX_BLOCK_CNT ? MAX_BLOCK_CNT : count; */
/*         unsigned bytes = bcnt * 512; */
/*         if (send_data_cmd(bcnt == 1 ? CMD17 : CMD18, sector, buf, bcnt, response) < 0) return 1; */
/*         if (bcnt > 1 && send_cmd(CMD12, 0, response) < 0) return 1; */
/*         sector += (card_type & CT_BLOCK) ? bcnt : bytes; */
/*         count -= bcnt; */
/*         buf += bytes; */
/*     } */

/*     return 0;; */
/* } */

int disk_read(BYTE * buf, LBA_t sector, UINT count) {
  uint64_t r;
  UINT i;
  
  uint8_t crc = 0;
  crc = crc7(crc, 0x40 | SD_CMD_READ_BLOCK_MULTIPLE);
  crc = crc7(crc, (sector >> 24) & 0xff);
  crc = crc7(crc, (sector >> 16) & 0xff);
  crc = crc7(crc, (sector >> 8) & 0xff);
  crc = crc7(crc, sector & 0xff);
  crc = crc | 1;
  
  if (sd_cmd(18, sector &, crc) != 0x00) {
    print_uart("disk_read: CMD18 failed. r = ");
    print_byte(r & 0xff);
    return -1;
  }

  // Begin reading 
  for (i = 0; i < count; i++) {
    
  }
}

// copyFlash: --------------------------------------------------------
// A lot happens in this function:
// * The Wally banner is printed
// * The peripherals are initialized
void copyFlash(QWORD address, QWORD * Dst, DWORD numBlocks) {
  int ret = 0;

  // Initialize UART for messages
  init_uart();
  
  // Print the wally banner
  print_uart(BANNER);

  // Intialize the SD card
  init_sd();
  
  ret = gpt_load_partitions(card_type);
}

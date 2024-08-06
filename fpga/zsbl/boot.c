#include <stddef.h>
#include "boot.h"
#include "gpt.h"
#include "uart.h"
#include "spi.h"
#include "sd.h"
#include "time.h"
#include "riscv.h"
#include "fail.h"

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

// Need to convert this
/* void print_progress(size_t count, size_t max) { */
/*     const int bar_width = 50; */

/*     float progress = (float) count / max; */
/*     int bar_length = progress * bar_width; */

/*     printf("\r["); */
/*     for (int i = 0; i < bar_length; ++i) { */
/*         printf("#"); */
/*     } */
/*     for (int i = bar_length; i < bar_width; ++i) { */
/*         printf("-"); */
/*     } */
/*     printf("] %.2f%%", progress * 100); */

/*     fflush(stdout); */
/* } */

int disk_read(BYTE * buf, LBA_t sector, UINT count) {
  uint64_t r;
  UINT i;
  volatile uint8_t *p = buf;

  UINT modulus = count/50;

  uint8_t crc = 0;
  crc = crc7(crc, 0x40 | SD_CMD_READ_BLOCK_MULTIPLE);
  crc = crc7(crc, (sector >> 24) & 0xff);
  crc = crc7(crc, (sector >> 16) & 0xff);
  crc = crc7(crc, (sector >> 8) & 0xff);
  crc = crc7(crc, sector & 0xff);
  crc = crc | 1;
  
  if ((r = sd_cmd(18, sector & 0xffffffff, crc) & 0xff) != 0x00) {
    print_uart("disk_read: CMD18 failed. r = 0x");
    print_uart_byte(r);
    print_uart("\r\n");
    fail();
    // return -1;
  }

  print_uart("\r          Blocks loaded: ");
  print_uart("0");
  print_uart("/");
  print_uart_dec(count);
  // write_reg(SPI_CSMODE, SIFIVE_SPI_CSMODE_MODE_HOLD);
  // Begin reading blocks
  for (i = 0; i < count; i++) {
    uint16_t crc, crc_exp;
    uint64_t n = 0;

    // Wait for data token
    while((r = spi_dummy()) != SD_DATA_TOKEN);
    // println_with_byte("Received data token: 0x", r & 0xff);

    // println_with_dec("Block ", i);
    // Read block into memory.
    /* for (int j = 0; j < 64; j++) { */
    /*   *buf = sd_read64(&crc); */
    /*   println_with_addr("0x", *buf); */
    /*   buf = buf + 64; */
    /* } */
    crc = 0;
    n = 512;
    do {
      uint8_t x = spi_dummy();
      *p++ = x;
      crc = crc16(crc, x);
    } while (--n > 0);
    
    // Read CRC16 and check
    crc_exp = ((uint16_t)spi_dummy() << 8);
    crc_exp |= spi_dummy();

    if (crc != crc_exp) {
      print_uart("Stinking CRC16 didn't match on block read.\r\n");
      print_uart_int(i);
      print_uart("\r\n");
      //return -1;
      fail();
    }

    if ( (i % modulus) == 0 ) {
      print_uart("\r          Blocks loaded: ");
      print_uart_dec(i);
      print_uart("/");
      print_uart_dec(count);
    }

  }

  sd_cmd(SD_CMD_STOP_TRANSMISSION, 0, 0x01);

  print_uart("\r          Blocks loaded: ");
  print_uart_dec(count);
  print_uart("/");
  print_uart_dec(count);
  // write_reg(SPI_CSMODE, SIFIVE_SPI_CSMODE_MODE_AUTO);
  //spi_txrx(0xff);
  print_uart("\r\n");
  return 0;
}

// copyFlash: --------------------------------------------------------
// A lot happens in this function:
// * The Wally banner is printed
// * The peripherals are initialized
void copyFlash(QWORD address, QWORD * Dst, DWORD numBlocks) {
  int ret = 0;

  // Initialize UART for messages
  init_uart(20000000, 115200);
  
  // Print the wally banner
  print_uart(BANNER);

  /* print_uart("System clock speed: "); */
  /* print_uart_dec(SYSTEMCLOCK); */
  /* print_uart("\r\n"); */

  // Intialize the SD card
  init_sd(SYSTEMCLOCK, 5000000);
  
  ret = gpt_load_partitions();
}

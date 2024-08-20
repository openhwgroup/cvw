///////////////////////////////////////////////////////////////////////
// boot.c
//
// Written: Jacob Pease jacob.pease@okstate.edu 7/22/2024
//
// Purpose: Main bootloader entry point
//
// 
//
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the
// “License”); you may not use this file except in compliance with the
// License, or, at your option, the Apache License version 2.0. You
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work
// distributed under the License is distributed on an “AS IS” BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
// implied. See the License for the specific language governing
// permissions and limitations under the License.
///////////////////////////////////////////////////////////////////////

#include <stddef.h>
#include "boot.h"
#include "gpt.h"
#include "uart.h"
#include "spi.h"
#include "sd.h"
#include "time.h"
#include "riscv.h"
#include "fail.h"


// Maximum SD card clock frequency is either 20MHz or half of the
// system clock

/*
PSEUDOCODE:
transmit 8 dummy bytes
wait for receive fifo to get a byte.
- as soon as a byte is in the receive fifo
- process the byte and increment a byte counter.
when 8 bytes are transferred


 */

int disk_read(BYTE * buf, LBA_t sector, UINT count) {
  uint64_t r;
  UINT i, j;
  volatile uint8_t *p = buf;

  // Quarter of the Systemclock, divided by the number of bits in a block
  // equals the number of blocks per second transferred.
  UINT modulus = SDCCLOCK/(8*512);

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

    crc = 0;
    n = 512;
    do {
      uint8_t x = spi_dummy();
      *p++ = x;
      crc = crc16(crc, x);
    } while (--n > 0);

    /* n = 512/8; */
    /* do { */
    /*   // Send 8 dummy bytes (fifo should be empty) */
    /*   for (j = 0; j < 8; j++) { */
    /*     spi_sendbyte(0xff); */
    /*   } */

    /*   // Reset counter. Process bytes AS THEY COME IN. */
    /*   for (j = 0; j < 8; j++) { */
    /*     while (!(read_reg(SPI_IP) & 2)) {} */
    /*     uint8_t x = spi_readbyte(); */
    /*     *p++ = x; */
    /*     crc = crc16(crc, x);         */
    /*   } */
    /* } while(--n > 0); */
    
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
  init_sd(SYSTEMCLOCK, SDCCLOCK);
  
  ret = gpt_load_partitions();
}

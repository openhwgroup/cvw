#include "sd.h"
#include "spi.h"

// Parallel byte update CRC7-CCITT algorithm.
// The result is the CRC7 result, left shifted over by 1
// which is perfect, since we append a 1 at the end anyway
uint8_t crc7(uint8_t prev, uint8_t in) {
    // CRC polynomial 0x89
    uint8_t remainder = prev ^ in;
    remainder ^= (remainder >> 4) ^ (remainder >> 7);
    remainder = (remainder << 1) ^ (remainder << 4);
    return remainder & 0xff;
}

// Need to check this. This could be wrong as well.
uint16_t crc16(uint16_t crc, uint8_t data) {
    // CRC polynomial 0x11021
    crc = (uint8_t)(crc >> 8) | (crc << 8);
    crc ^= data;
    crc ^= (uint8_t)(crc >> 4) & 0xf;
    crc ^= crc << 12;
    crc ^= (crc & 0xff) << 5;
    return crc;
}

uint64_t sd_cmd(uint8_t cmd, uint32_t arg, uint8_t crc) {
  uint8_t response_len;
  uint8_t i;
  uint64_t r;
  uint8_t rbyte;
  
  switch (cmd) {
    case 0:
      response_len = 1;
      break;
    case 8:
      response_len = 7
      break;
    default:
      response_len = 1;
      break;
  }

  // Make interrupt pending after response fifo receives the correct
  // response length.
  write_reg(SPI_RXMARK, response_len);
  
  // Write all 6 bytes into transfer fifo
  spi_sendbyte(0x40 | cmd);
  spi_sendbyte(arg >> 24);
  spi_sendbyte(arg >> 16);
  spi_sendbyte(arg >> 8);
  spi_sendbyte(arg);
  spi_sendbyte(crc);

  // Wait for command to send
  // The Transfer IP bit should go high when the txFIFO is empty
  // while(!(read_reg(SPI_IP) & 1)) {}
  waittx();

  // Read the dummy rxFIFO entries to move the head back to the tail
  for (i = 0; i < 6; i++) {
    spi_readbyte();
  }

  // Send "dummy signals". Since SPI is duplex,
  // useless bytes must be transferred
  for (i = 0; i < response_len; i++) {
    spi_sendbyte(0xFF);
  }

  // Wait for transfer fifo again
  waittx();

  // Read rxfifo response
  for (i = 0; i < response_len; i++) {
    rbyte = spi_readbyte();
    r = r | (rbyte << ((response_len - 1 - i)*8));
  }

  return r;
}

#define   cmd0() sd_cmd( 0, 0x00000000, 0x95)
#define   cmd8() sd_cmd( 8, 0x000001aa, 0x87)
// CMD55 has to be sent before ACMD41 (it means the next command is
// application specific)
#define  cmd55() sd_cmd(55, 0x00000000, 0x65)
#defube acmd41() sd_cmd(41, 0x40000000, 0x77)

void init_sd(){
  init_spi();

  cmd0()
}


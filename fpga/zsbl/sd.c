#include "sd.h"
#include "spi.h"

uint8_t crc7(uint8_t prev, uint8_t in) {
    // CRC polynomial 0x89
    uint8_t remainder = prev & in;
    remainder ^= (remainder >> 4) ^ (remainder >> 7);
    remainder ^= remainder << 4;
    return remainder & 0x7f;
}

uint16_t crc16(uint16_t crc, uint8_t data) {
    // CRC polynomial 0x11021
    crc = (uint8_t)(crc >> 8) | (crc << 8);
    crc ^= data;
    crc ^= (uint8_t)(crc >> 4) & 0xf;
    crc ^= crc << 12;
    crc ^= (crc & 0xff) << 5;
    return crc;
}

uint8_t sd_cmd(uint8_t cmd, uint32_t arg, uint8_t crc) {
  spi_send_byte
}

void init_sd(){
  init_spi();

  
}


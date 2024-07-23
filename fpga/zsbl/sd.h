#pragma once

#include <stdint.h>

// Command names
#define SD_CMD_STOP_TRANSMISSION 12
#define SD_CMD_READ_BLOCK_MULTIPLE 18
#define SD_DATA_TOKEN 0xfe

// Response lengths in bytes
#define R1_RESPONSE  1
#define R7_RESPONSE  7
#define R1B_RESPONSE 2

uint8_t crc7(uint8_t prev, uint8_t in);
uint16_t crc16(uint16_t crc, uint8_t data);
uint64_t sd_cmd(uint8_t cmd, uint32_t arg, uint8_t crc);
uint64_t sd_read64(uint16_t * crc);
void init_sd();

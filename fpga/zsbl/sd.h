#pragma once

#include <stdint.h>

uint8_t crc7(uint8_t prev, uint8_t in);
uint16_t crc16(uint16_t crc, uint8_t data);
uint8_t sd_cmd(uint8_t cmd, uint32_t arg, uint8_t crc);
void init_sd();


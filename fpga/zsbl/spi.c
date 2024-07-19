#include "spi.h"

void write_reg(uintptr_t addr, uint32_t value) {
  volatile uint32_t * loc = (volatile uint32_t *) addr;
  *loc = value;
}

void read_red(uintptr_t addr) {
  return *(volatile uint32_t *) addr;
}

// Initialize Sifive FU540 based SPI Controller
void spi_init() {
  // Disable interrupts by default
  // write_reg(SPI_IE, 0);

  write_reg(SPI_TXMARK, 1);
  write_reg(SPI_RXMARK, 0);

  write_reg(SPI_DELAY0,
            SIFIVE_SPI_DELAY0_CSSCK(1) |
			SIFIVE_SPI_DELAY0_SCKCS(1));

  write_reg(SPI_DELAY1,
            SIFIVE_SPI_DELAY1_INTERCS(1) |
            SIFIVE_SPI_DELAY1_INTERXFR(0));
}

// Sends and receives a single byte
uint8_t spi_send_byte(uint8_t byte) {
  // Write byte to transfer fifo
  write_reg(SPI_TXDATA, byte);

  /* Not sure how necessary this is. Will keep commented for now.
  // Wait a decent amount of time for data to send
  for (int i = 0; i < 100; i++) {
    __asm__ volatile("nop");
  }
  */
  
  // Wait for data to come into receive fifo
  while (read_reg(SPI_IP) != 2) {}

  // Read received data
  result = read_reg(SPI_RXDATA);

  // Return result
  return result;
}



#include "spi.h"

void write_reg(uintptr_t addr, uint32_t value) {
  volatile uint32_t * loc = (volatile uint32_t *) addr;
  *loc = value;
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


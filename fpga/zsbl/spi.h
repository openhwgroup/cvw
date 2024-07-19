#pragma once
#ifndef SPI_HEADER
#define SPI_HEADER

#include <stdint.h>

/* register offsets */
#define SPI_SCKDIV            0x00 /* Serial clock divisor */
#define SPI_SCKMODE           0x04 /* Serial clock mode */
#define SPI_CSID              0x10 /* Chip select ID */
#define SPI_CSDEF             0x14 /* Chip select default */
#define SPI_CSMODE            0x18 /* Chip select mode */
#define SPI_DELAY0            0x28 /* Delay control 0 */
#define SPI_DELAY1            0x2c /* Delay control 1 */
#define SPI_FMT               0x40 /* Frame format */
#define SPI_TXDATA            0x48 /* Tx FIFO data */
#define SPI_RXDATA            0x4c /* Rx FIFO data */
#define SPI_TXMARK            0x50 /* Tx FIFO [<35;39;29Mwatermark */
#define SPI_RXMARK            0x54 /* Rx FIFO watermark */

/* Non-implemented
#define SPI_FCTRL             0x60 // SPI flash interface control
#define SPI_FFMT              0x64 // SPI flash instruction format
*/
#define SPI_IE                0x70 /* Interrupt Enable Register */
#define SPI_IP                0x74 /* Interrupt Pendings Register */

/* delay0 bits */
#define SIFIVE_SPI_DELAY0_CSSCK(x)       ((u32)(x))
#define SIFIVE_SPI_DELAY0_CSSCK_MASK     0xffU
#define SIFIVE_SPI_DELAY0_SCKCS(x)       ((u32)(x) << 16)
#define SIFIVE_SPI_DELAY0_SCKCS_MASK     (0xffU << 16)

/* delay1 bits */
#define SIFIVE_SPI_DELAY1_INTERCS(x)     ((u32)(x))
#define SIFIVE_SPI_DELAY1_INTERCS_MASK   0xffU
#define SIFIVE_SPI_DELAY1_INTERXFR(x)    ((u32)(x) << 16)
#define SIFIVE_SPI_DELAY1_INTERXFR_MASK  (0xffU << 16)

void write_reg(uintptr_t addr, uint32_t value);
uint32_t read_reg(uintptr_t addr);
uint8_t spi_send_byte(uint8_t byte);
void spi_init();

#endif

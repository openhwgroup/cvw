#pragma once
#include <stdint.h>

#define UART_BASE 0x10000000

#define UART_RBR UART_BASE + 0x00
#define UART_THR UART_BASE + 0x00
#define UART_IER UART_BASE + 0x01
#define UART_IIR UART_BASE + 0x02
#define UART_FCR UART_BASE + 0x02
#define UART_LCR UART_BASE + 0x03
#define UART_MCR UART_BASE + 0x04
#define UART_LSR UART_BASE + 0x05
#define UART_MSR UART_BASE + 0x06
#define UART_SCR UART_BASE + 0x07
#define UART_DLL UART_BASE + 0x00
#define UART_DLM UART_BASE + 0x01

void init_uart();
void write_reg_u8(uintptr_t addr, uint8_t value);
uint8_t read_reg_u8(uintptr_t addr);
int read_serial(uint8_t *res);
void print_uart(const char* str);
void print_uart_int(uint32_t addr);
void print_uart_addr(uint64_t addr);
void print_uart_byte(uint8_t byte);

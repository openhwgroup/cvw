// wally-macros.sv
// David_Harris@hmc.edu 5 January 2021

// Macros to determine which mode is supported based on MISA

`define A_SUPPORTED ((MISA >> 0) % 2 == 1)
`define C_SUPPORTED ((MISA >> 2) % 2 == 1)
`define D_SUPPORTED ((MISA >> 3) % 2 == 1)
`define F_SUPPORTED ((MISA >> 5) % 2 == 1)
`define M_SUPPORTED ((MISA >> 12) % 2 == 1)
`define S_SUPPORTED ((MISA >> 18) % 2 == 1)
`define U_SUPPORTED ((MISA >> 20) % 2 == 1)
`define ZCSR_SUPPORTED (ZCSR != 0)
`define ZCOUNTERS_SUPPORTED (ZCOUNTERS != 0)
// N-mode user-level interrupts are depricated per Andrew Waterman 1/13/21
//`define N_SUPPORTED ((MISA >> 13) % 2 == 1)
`define N_SUPPORTED 0

`define M_MODE (2'b11)
`define S_MODE (2'b01)
`define U_MODE (2'b00)

/* verilator lint_off STMTDLY */
/* verilator lint_off WIDTH */

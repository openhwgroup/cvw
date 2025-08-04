`ifndef DMI_VH
`define DMI_VH

// Width of Debug Transport Module instructions inside the instruction
// register.
`define INSTWIDTH 5
 
// ABITS is equal to the width of Addresses inside the Debug Module.
`define ABITS 7

// DTM Control and Status register fields
typedef struct packed {
    logic [10:0] reserved0 = '0; // all 0s
    logic [2:0] errinfo = 4;
    logic       dtmhardreset = 0;
    logic       dmireset = 0;
    logic reserved1 = '0;       // single 0
    logic [2:0] idle;
    logic [1:0] dmistat;
    logic [5:0] abits;
    logic [3:0] version;
} dtmcs_t;
  
// Debug Module Interface fields
typedef struct packed {
    logic [6:0] addr;
    logic [31:0] data;
    logic [1:0]  op;
} dmi_t;

// Currently implemented instructions for the Debug Transport Module.
typedef enum logic [4:0] {
    BYPASS = 5'b11111,
    IDCODE = 5'b00001,
    DTMCS  = 5'b10000,
    DMIREG = 5'b10001
} DTMINST;

`define DTMCS_RESET 32'h
`define DMI_WIDTH `ABITS + 32 + 2
`define DMI_RESET `DMI_WIDTH'h

`endif

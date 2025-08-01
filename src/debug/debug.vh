`ifndef DMI_VH
`define DMI_VH

// Debug Module Interface fields
typedef struct packed {
    logic [6:0] addr;
    logic [31:0] data;
    logic [1:0]  op;
} dmi_t;

`endif

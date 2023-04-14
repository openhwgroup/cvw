localparam VPN_SEGMENT_BITS = (LLEN == 32 ? 10 : 9);


// macros to define supported modes
localparam A_SUPPORTED = ((MISA >> 0) % 2 == 1);
localparam B_SUPPORTED = ((ZBA_SUPPORTED | ZBB_SUPPORTED | ZBC_SUPPORTED | ZBS_SUPPORTED));// not based on MISA
localparam C_SUPPORTED = ((MISA >> 2) % 2 == 1);
localparam D_SUPPORTED = ((MISA >> 3) % 2 == 1);
localparam E_SUPPORTED = ((MISA >> 4) % 2 == 1);
localparam F_SUPPORTED = ((MISA >> 5) % 2 == 1);
localparam I_SUPPORTED = ((MISA >> 8) % 2 == 1);
localparam M_SUPPORTED = ((MISA >> 12) % 2 == 1);
localparam Q_SUPPORTED = ((MISA >> 16) % 2 == 1);
localparam S_SUPPORTED = ((MISA >> 18) % 2 == 1);
localparam U_SUPPORTED = ((MISA >> 20) % 2 == 1);
// N-mode user-level interrupts are depricated per Andrew Waterman 1/13/21

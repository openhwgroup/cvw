//max function
`define max(a,b) (((a) > (b)) ? (a) : (b))

// constants defining different privilege modes
// defined in Table 1.1 of the privileged spec
localparam M_MODE  = (2'b11);
localparam S_MODE  = (2'b01);
localparam U_MODE  = (2'b00);

// Virtual Memory Constants
localparam VPN_SEGMENT_BITS = (XLEN == 32 ? 32'd10 : 32'd9);
localparam VPN_BITS = (XLEN==32 ? (2*VPN_SEGMENT_BITS) : (4*VPN_SEGMENT_BITS));
localparam PPN_BITS = (XLEN==32 ? 32'd22 : 32'd44);
localparam PA_BITS = (XLEN==32 ? 32'd34 : 32'd56);
localparam SVMODE_BITS = (XLEN==32 ? 32'd1 : 32'd4);
localparam ASID_BASE = (XLEN==32 ? 32'd22 : 32'd44);
localparam ASID_BITS = (XLEN==32 ? 32'd9 : 32'd16);

// constants to check SATP_MODE against
// defined in Table 4.3 of the privileged spec
localparam NO_TRANSLATE = 4'd0;
localparam SV32 = 4'd1;
localparam SV39 = 4'd8;
localparam SV48 = 4'd9;

// macros to define supported modes
localparam A_SUPPORTED = ((MISA >> 0) % 2 == 1);
localparam B_SUPPORTED = ((ZBA_SUPPORTED | ZBB_SUPPORTED | ZBC_SUPPORTED | ZBS_SUPPORTED));// not based on MISA
localparam C_SUPPORTED = ((MISA >> 2) % 2 == 1);
localparam COMPRESSED_SUPPORTED = C_SUPPORTED | ZCA_SUPPORTED;
localparam D_SUPPORTED = ((MISA >> 3) % 2 == 1);
localparam E_SUPPORTED = ((MISA >> 4) % 2 == 1);
localparam F_SUPPORTED = ((MISA >> 5) % 2 == 1);
localparam I_SUPPORTED = ((MISA >> 8) % 2 == 1);
localparam K_SUPPORTED = ((ZBKB_SUPPORTED | ZBKC_SUPPORTED | ZBKX_SUPPORTED | ZKND_SUPPORTED | ZKNE_SUPPORTED | ZKNH_SUPPORTED));
localparam M_SUPPORTED = ((MISA >> 12) % 2 == 1);
localparam Q_SUPPORTED = ((MISA >> 16) % 2 == 1);
localparam S_SUPPORTED = ((MISA >> 18) % 2 == 1);
localparam U_SUPPORTED = ((MISA >> 20) % 2 == 1);
// N-mode user-level interrupts are depricated per Andrew Waterman 1/13/21

// logarithm of XLEN, used for number of index bits to select
localparam LOG_XLEN = (XLEN == 32 ? 32'd5 : 32'd6);

// Number of 64 bit PMP Configuration Register entries (or pairs of 32 bit entries)
localparam PMPCFG_ENTRIES = (PMP_ENTRIES/32'd8);

// Floating point constants for Quad, Double, Single, and Half precisions
// Lim: I've made some of these 64 bit to avoid width warnings. 
// If errors crop up, try downsizing back to 32.
localparam Q_LEN = 32'd128;
localparam Q_NE = 32'd15;
localparam Q_NF = 32'd112;
localparam Q_BIAS = 32'd16383;
localparam Q_FMT = 2'd3;
localparam D_LEN = 32'd64;
localparam D_NE = 32'd11;
localparam D_NF = 32'd52;
localparam D_BIAS = 32'd1023;
localparam D_FMT = 2'd1;
localparam S_LEN = 32'd32;
localparam S_NE = 32'd8;
localparam S_NF = 32'd23;
localparam S_BIAS = 32'd127;
localparam S_FMT = 2'd0;
localparam H_LEN = 32'd16;
localparam H_NE = 32'd5;
localparam H_NF = 32'd10;
localparam H_BIAS = 32'd15;
localparam H_FMT = 2'd2;

// Floating point length FLEN and number of exponent (NE) and fraction (NF) bits (for longest format supported)
localparam FLEN = Q_SUPPORTED ? Q_LEN  : D_SUPPORTED ? D_LEN  : S_LEN;
localparam NE   = Q_SUPPORTED ? Q_NE   : D_SUPPORTED ? D_NE   : S_NE;
localparam NF   = Q_SUPPORTED ? Q_NF   : D_SUPPORTED ? D_NF   : S_NF;
localparam FMT  = Q_SUPPORTED ? 2'd3   : D_SUPPORTED ? 2'd1   : 2'd0;
localparam BIAS = Q_SUPPORTED ? Q_BIAS : D_SUPPORTED ? D_BIAS : S_BIAS;

// Floating point constants needed for FPU paramerterization
// LEN1/NE1/NF1/FNT1 is the size of the second longest supported format
localparam FPSIZES = (32)'(Q_SUPPORTED)+(32)'(D_SUPPORTED)+(32)'(F_SUPPORTED)+(32)'(ZFH_SUPPORTED);
localparam FMTBITS = (32)'(FPSIZES>=3)+1;
localparam LEN1  = (FLEN > D_LEN) ? D_LEN  : (FLEN > S_LEN) ? S_LEN  : H_LEN;
localparam NE1   = (FLEN > D_LEN) ? D_NE   : (FLEN > S_LEN) ? S_NE   : H_NE;
localparam NF1   = (FLEN > D_LEN) ? D_NF   : (FLEN > S_LEN) ? S_NF   : H_NF;
localparam FMT1  = (FLEN > D_LEN) ? 2'd1   : (FLEN > S_LEN) ? 2'd0   : 2'd2;
localparam BIAS1 = (FLEN > D_LEN) ? D_BIAS : (FLEN > S_LEN) ? S_BIAS : H_BIAS;

// LEN2 etc is the size of the third longest supported format
localparam LEN2  = (LEN1 > S_LEN) ? S_LEN  : H_LEN;
localparam NE2   = (LEN1 > S_LEN) ? S_NE   : H_NE;
localparam NF2   = (LEN1 > S_LEN) ? S_NF   : H_NF;
localparam FMT2  = (LEN1 > S_LEN) ? 2'd0   : 2'd2;
localparam BIAS2 = (LEN1 > S_LEN) ? S_BIAS : H_BIAS;

// divider r and rk (bits per digit, bits per cycle)
localparam LOGR        = $clog2(RADIX);                             // r = log(R) bits per digit
localparam RK          = LOGR*DIVCOPIES;                            // r*k bits per cycle generated

// intermediate division parameters not directly used in fdivsqrt hardware
localparam FPDIVMINb   = NF + 2; // minimum length of fractional part: Nf result bits + guard and round bits + 1 extra bit to allow sqrt being shifted right
localparam DIVMINb     = ((FPDIVMINb<XLEN) & IDIV_ON_FPU) ? XLEN : FPDIVMINb; // minimum fractional bits b = max(XLEN, FPDIVMINb)
localparam RESBITS     = DIVMINb + LOGR; // number of bits in a result: r integer + b fractional

// division constants
localparam FPDUR       = (RESBITS-1)/RK + 1 ;                       // ceiling((r+b)/rk)
localparam DIVb        = FPDUR*RK - LOGR;                           // divsqrt fractional bits, so total number of bits is a multiple of rk after r integer bits
localparam DURLEN      = $clog2(FPDUR);                             // enough bits to count the duration
localparam DIVBLEN     = $clog2(DIVb+1);                            // enough bits to count number of fractional bits + 1 integer bit

// largest length in IEU/FPU
localparam BASECVTLEN = `max(XLEN, NF); // convert length excluding Zfa fcvtmod.w.d
localparam CVTLEN = (ZFA_SUPPORTED & D_SUPPORTED) ? `max(BASECVTLEN, 32'd84) : BASECVTLEN; // fcvtmod.w.d needs at least 32+52 because a double with 52 fractional bits might be into upper bits of 32 bit word
localparam LLEN = `max($unsigned(FLEN), $unsigned(XLEN));
localparam LOGCVTLEN = $unsigned($clog2(CVTLEN+1));

// NORMSHIFTSIZE is the bits out of the normalization shifter
// RV32F: max(32+23+1, 2(23)+4, 3(23)+6) = 3*23+6 = 75
// RV64F: max(64+23+1, 64 + 23 + 2, 3*23+6) = 89
// RV64D: max(84+52+1, 64+52+2, 3*52+6) = 162
localparam NORMSHIFTSZ = `max(`max((CVTLEN+NF+1), (DIVb + 1 + NF + 1)), (3*NF+6));

localparam LOGNORMSHIFTSZ = ($clog2(NORMSHIFTSZ));                  // log_2(NORMSHIFTSZ)
localparam CORRSHIFTSZ = NORMSHIFTSZ-2;                             // Drop leading 2 integer bits


// Disable spurious Verilator warnings

/* verilator lint_off STMTDLY */
/* verilator lint_off ASSIGNDLY */
/* verilator lint_off PINCONNECTEMPTY */

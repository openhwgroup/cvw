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

// Floating point length FLEN and number of exponent (NE) and fraction (NF) bits
localparam FLEN = (Q_SUPPORTED ? Q_LEN  : D_SUPPORTED ? D_LEN  : S_LEN);
localparam NE   = (Q_SUPPORTED ? Q_NE   : D_SUPPORTED ? D_NE   : S_NE);
localparam NF   = (Q_SUPPORTED ? Q_NF   : D_SUPPORTED ? D_NF   : S_NF);
localparam FMT  = (Q_SUPPORTED ? 2'd3    : D_SUPPORTED ? 2'd1    : 2'd0);
localparam BIAS = (Q_SUPPORTED ? Q_BIAS : D_SUPPORTED ? D_BIAS : S_BIAS);
/* Delete once tested dh 10/10/22

localparam FLEN = (Q_SUPPORTED ? Q_LEN  : D_SUPPORTED ? D_LEN  : F_SUPPORTED ? S_LEN  : H_LEN);
localparam NE   = (Q_SUPPORTED ? Q_NE   : D_SUPPORTED ? D_NE   : F_SUPPORTED ? S_NE   : H_NE);
localparam NF   = (Q_SUPPORTED ? Q_NF   : D_SUPPORTED ? D_NF   : F_SUPPORTED ? S_NF   : H_NF); 
localparam FMT  = (Q_SUPPORTED ? 2'd3       : D_SUPPORTED ? 2'd1       : F_SUPPORTED ? 2'd0       : 2'd2);
localparam BIAS = (Q_SUPPORTED ? Q_BIAS : D_SUPPORTED ? D_BIAS : F_SUPPORTED ? S_BIAS : H_BIAS);*/

// Floating point constants needed for FPU paramerterization
localparam FPSIZES = ((32)'(Q_SUPPORTED)+(32)'(D_SUPPORTED)+(32)'(F_SUPPORTED)+(32)'(ZFH_SUPPORTED));
localparam FMTBITS = ((32)'(FPSIZES>=3)+1);
localparam LEN1  = ((D_SUPPORTED & (FLEN != D_LEN)) ? D_LEN  : (F_SUPPORTED & (FLEN != S_LEN)) ? S_LEN  : H_LEN);
localparam NE1   = ((D_SUPPORTED & (FLEN != D_LEN)) ? D_NE   : (F_SUPPORTED & (FLEN != S_LEN)) ? S_NE   : H_NE);
localparam NF1   = ((D_SUPPORTED & (FLEN != D_LEN)) ? D_NF   : (F_SUPPORTED & (FLEN != S_LEN)) ? S_NF   : H_NF);
localparam FMT1  = ((D_SUPPORTED & (FLEN != D_LEN)) ? 2'd1    : (F_SUPPORTED & (FLEN != S_LEN)) ? 2'd0    : 2'd2);
localparam BIAS1 = ((D_SUPPORTED & (FLEN != D_LEN)) ? D_BIAS : (F_SUPPORTED & (FLEN != S_LEN)) ? S_BIAS : H_BIAS);
localparam LEN2  = ((F_SUPPORTED & (LEN1 != S_LEN)) ? S_LEN  : H_LEN);
localparam NE2   = ((F_SUPPORTED & (LEN1 != S_LEN)) ? S_NE   : H_NE);
localparam NF2   = ((F_SUPPORTED & (LEN1 != S_LEN)) ? S_NF   : H_NF);
localparam FMT2  = ((F_SUPPORTED & (LEN1 != S_LEN)) ? 2'd0    : 2'd2);
localparam BIAS2 = ((F_SUPPORTED & (LEN1 != S_LEN)) ? S_BIAS : H_BIAS);

// division constants
localparam DIVN        = (((NF+2<XLEN) & IDIV_ON_FPU) ? XLEN : NF+2); // standard length of input
localparam LOGR        = ($clog2(RADIX));           // r = log(R)
localparam RK          = (LOGR*DIVCOPIES);         // r*k used for intdiv preproc
localparam LOGRK       = ($clog2(RK));               // log2(r*k)
localparam FPDUR       = ((DIVN+1+(LOGR*DIVCOPIES))/(LOGR*DIVCOPIES)+(RADIX/4));
localparam DURLEN      = ($clog2(FPDUR+1));
localparam DIVb        = (FPDUR*LOGR*DIVCOPIES-1); // canonical fdiv size (b)
localparam DIVBLEN     = ($clog2(DIVb+1)-1);
localparam DIVa        = (DIVb+1-XLEN); // used for idiv on fpu: Shift residual right by b - (XLEN-1) to put remainder in lsbs of integer result

// largest length in IEU/FPU
localparam CVTLEN = ((NF<XLEN) ? (XLEN) : (NF));  // max(XLEN, NF)
localparam LLEN = (($unsigned(FLEN)<$unsigned(XLEN)) ? ($unsigned(XLEN)) : ($unsigned(FLEN)));
localparam LOGCVTLEN = $unsigned($clog2(CVTLEN+1));
localparam NORMSHIFTSZ = (((CVTLEN+NF+1)>(DIVb + 1 +NF+1) & (CVTLEN+NF+1)>(3*NF+6)) ? (CVTLEN+NF+1) : ((DIVb + 1 +NF+1) > (3*NF+6) ? (DIVb + 1 +NF+1) : (3*NF+6)));
localparam LOGNORMSHIFTSZ = ($clog2(NORMSHIFTSZ));
localparam CORRSHIFTSZ = (((CVTLEN+NF+1)>(DIVb + 1 +NF+1) & (CVTLEN+NF+1)>(3*NF+6)) ? (CVTLEN+NF+1) : ((DIVN+1+NF) > (3*NF+4) ? (DIVN+1+NF) : (3*NF+4)));


// Disable spurious Verilator warnings

/* verilator lint_off STMTDLY */
/* verilator lint_off ASSIGNDLY */
/* verilator lint_off PINCONNECTEMPTY */

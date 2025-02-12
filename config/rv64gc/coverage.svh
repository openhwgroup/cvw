// coverage.svh
// David_Harris@hmc.edu 7 September 2024
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

// This file is needed in the config subdirectory for each config supporting coverage.
// It defines which extensions are enabled for that config.

// Define XLEN, used in covergroups
`define XLEN64

// Define relevant addresses
`define ACCESS_FAULT_ADDRESS 64'h00000000
`define CLINT_BASE 64'h02000000

// Unprivileged extensions
`define I_COVERAGE
`define M_COVERAGE
`define F_COVERAGE
`define D_COVERAGE
`define ZBA_COVERAGE
`define ZBB_COVERAGE
`define ZBC_COVERAGE
`define ZBS_COVERAGE
`define ZFA_F_COVERAGE
`define ZFA_D_COVERAGE
`define ZFA_ZFH_COVERAGE
`define ZFA_ZFH_D_COVERAGE
`define ZFH_COVERAGE
`define ZFH_D_COVERAGE
// Note: Zfhmin is a subset of Zfh, so usually only one or the other would be used.  When Zfhmin and D are supported, ZfhD should also be enabled
`define ZFHMIN_COVERAGE
`define ZFHMIN_D_COVERAGE
// Note: Zmmul is a subset of M, so usually only one or the other would be used.
`define ZMMUL_COVERAGE
`define ZICOND_COVERAGE
`define ZCA_COVERAGE
`define ZCB_COVERAGE
`define ZCB_M_COVERAGE
`define ZCB_ZBB_COVERAGE
`define ZCB_ZBA_COVERAGE
`define ZCD_COVERAGE
`define ZICSR_COVERAGE
`define ZBKB_COVERAGE
`define ZBKC_COVERAGE
`define ZBKX_COVERAGE
`define ZKND_COVERAGE
`define ZKNE_COVERAGE
`define ZKNH_COVERAGE
`define ZAAMO_COVERAGE
`define ZALRSC_COVERAGE

// Privileged extensions
`define RV64VM_COVERAGE
`define ZICSRM_COVERAGE
`define ZICSRF_COVERAGE
`define ZICSRU_COVERAGE
`define ENDIANU_COVERAGE
`define ENDIANS_COVERAGE
`define ENDIANM_COVERAGE
`define EXCEPTIONSM_COVERAGE
`define EXCEPTIONSZC_COVERAGE
`define ZICNTRU_COVERAGE
`define ZICNTRS_COVERAGE
`define ZICNTRM_COVERAGE

// `define RV64VM_PMP_COVERAGE
// `define RV64CBO_VM_COVERAGE
// `define RV64CBO_PMP_COVERAGE

// coverage.svh
// David_Harris@hmc.edu 7 September 2024
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

// This file is needed in the config subdirectory for each config supporting coverage.
// It defines which extensions are enabled for that config.

// Define XLEN, used in covergroups
`define XLEN64 1

// Define relevant addresses
`define ACCESS_FAULT_ADDRESS 64'h00000000
`define CLINT_BASE 64'h02000000

// Unprivileged extensions
`include "I_coverage.svh"
`include "M_coverage.svh"
`include "F_coverage.svh"
`include "D_coverage.svh"
`include "Zba_coverage.svh"
`include "Zbb_coverage.svh"
`include "Zbc_coverage.svh"
`include "Zbs_coverage.svh"
`include "ZfaF_coverage.svh"
`include "ZfaD_coverage.svh"
`include "ZfaZfh_coverage.svh"
`include "ZfhD_coverage.svh"
`include "Zfh_coverage.svh"
// Note: Zfhmin is a subset of Zfh, so usually only one or the other would be used.  When Zfhmin and D are supported, ZfhD should also be enabled
`include "Zfhmin_coverage.svh"
// Note: Zmmul is a subset of M, so usually only one or the other would be used.
`include "Zmmul_coverage.svh"
`include "Zicond_coverage.svh"
`include "Zca_coverage.svh"
`include "Zcb_coverage.svh"
`include "ZcbM_coverage.svh"
`include "ZcbZbb_coverage.svh"
`include "ZcbZba_coverage.svh"
`include "Zcd_coverage.svh"
`include "Zicsr_coverage.svh"
`include "Zbkb_coverage.svh"
`include "Zbkc_coverage.svh"
`include "Zbkx_coverage.svh"
`include "Zknd_coverage.svh"
`include "Zkne_coverage.svh"
`include "Zknh_coverage.svh"
`include "Zaamo_coverage.svh"
`include "Zalrsc_coverage.svh"

// Privileged extensions
`include "RV64VM_coverage.svh"
`include "ZicsrM_coverage.svh"
`include "ZicsrF_coverage.svh"
`include "ZicsrU_coverage.svh"
`include "EndianU_coverage.svh"
`include "EndianM_coverage.svh"
`include "EndianS_coverage.svh"
`include "ExceptionsM_coverage.svh"
`include "ExceptionsZc_coverage.svh"
// `include "RV64VM_PMP_coverage.svh"
// `include "RV64CBO_VM_coverage.svh"
// `include "RV64CBO_PMP_coverage.svh"
// `include "RV64Zicbom_coverage.svh"

// coverage.svh
// David_Harris@hmc.edu 7 September 2024
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

// This file is needed in the config subdirectory for each config supporting coverage.
// It defines which extensions are enabled for that config.

// Unprivileged extensions
`include "RV64I_coverage.svh"
`include "RV64M_coverage.svh"
`include "RV64F_coverage.svh"
`include "RV64D_coverage.svh"
`include "RV64ZfaF_coverage.svh"
`include "RV32ZfaD_coverage.svh"
`include "RV32ZfaZfh_coverage.svh"
`include "RV64ZfhD_coverage.svh"
`include "RV64Zfh_coverage.svh"
`include "RV64Zicond_coverage.svh"
`include "RV64Zca_coverage.svh"
`include "RV64Zcb_coverage.svh"
`include "RV64ZcbM_coverage.svh"
`include "RV64ZcbZbb_coverage.svh"
`include "RV64ZcbZba_coverage.svh"
`include "RV64Zcd_coverage.svh"

// Privileged extensions
`include "RV64VM_coverage.svh"
`include "ZicsrM_coverage.svh"
// `include "RV64VM_PMP_coverage.svh"
// `include "RV64CBO_VM_coverage.svh"
// `include "RV64CBO_PMP_coverage.svh"
// `include "RV64Zicbom_coverage.svh"

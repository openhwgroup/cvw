// coverage.svh
// David_Harris@hmc.edu 7 September 2024
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

// This file is needed in the config subdirectory for each config supporting coverage.
// It defines which extensions are enabled for that config.

// Unprivileged extensions
`include "RV32I_coverage.svh"
`include "RV32M_coverage.svh"
`include "RV32F_coverage.svh"
`include "RV32D_coverage.svh"
`include "RV32ZfaF_coverage.svh"
`include "RV32ZfaD_coverage.svh"
`include "RV32ZfaZfh_coverage.svh"
`include "RV32ZfhD_coverage.svh"
`include "RV32Zfh_coverage.svh"
`include "RV32Zicond_coverage.svh"
`include "RV32Zca_coverage.svh"
`include "RV32Zcb_coverage.svh"
`include "RV32ZcbM_coverage.svh"
`include "RV32ZcbZbb_coverage.svh"
`include "RV32Zcf_coverage.svh"
`include "RV32Zcd_coverage.svh"

// Privileged extensions
`include "ZicsrM_coverage.svh"

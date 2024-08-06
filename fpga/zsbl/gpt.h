///////////////////////////////////////////////////////////////////////
// gpt.h
//
// Written: Jaocb Pease jacob.pease@okstate.edu 7/22/2024
//
// Purpose: Header for gpt.c, contains gpt structs
//
// 
//
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the
// “License”); you may not use this file except in compliance with the
// License, or, at your option, the Apache License version 2.0. You
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work
// distributed under the License is distributed on an “AS IS” BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
// implied. See the License for the specific language governing
// permissions and limitations under the License.
///////////////////////////////////////////////////////////////////////

#pragma once

#include <stdint.h>
#include "boot.h"

// LBA 0: Protective MBR
// ignored here

// Partition Table Header (LBA 1)
typedef struct gpt_pth
{
    uint64_t signature;
    uint32_t revision;
    uint32_t header_size; //! little endian, usually 0x5c = 92
    uint32_t crc_header;
    uint32_t reserved; //! must be 0
    uint64_t current_lba;
    uint64_t backup_lba;
    uint64_t first_usable_lba;
    uint64_t last_usable_lba;
    uint8_t disk_guid[16];
    uint64_t partition_entries_lba;
    uint32_t nr_partition_entries;
    uint32_t size_partition_entry; //! usually 0x80 = 128
    uint32_t crc_partition_entry;
} gpt_pth_t;

// Partition Entries (LBA 2-33)
typedef struct partition_entries
{
    uint8_t partition_type_guid[16];
    uint8_t partition_guid[16];
    uint64_t first_lba;
    uint64_t last_lba; //! inclusive
    uint64_t attributes;
    uint8_t name[72]; //! utf16 encoded
} partition_entries_t;

// Find boot partition and load it to the destination
int gpt_load_partitions();

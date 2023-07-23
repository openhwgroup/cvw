#include "gpt.h"
#include "boot.h"
#include <stddef.h>

/* PSUEDOCODE

   Need to load GPT LBA 1 and read through the partition entries.
   I need to find each of the relevant partition entries, possibly
   by their partition names.
   
*/

int gpt_load_partitions(BYTE card_type) {
  // In this version of the GPT partition code
  // I'm going to assume that the SD card is already initialized.

  // size_t block_size = 512/8;
  // long int lba1_buf[block_size];

  BYTE lba1_buf[512];
  
  int ret = 0;
  //ret = disk_read(/* BYTE * buf, LBA_t sector, UINT count, BYTE card_type */);
  ret = disk_read(lba1_buf, 1, 1, card_type);

  /* Possible error handling with UART message
  if ( ret != 0 ) {
    
  }*/

  gpt_pth_t *lba1 = (gpt_pth_t *)lba1_buf;

  BYTE lba2_buf[512];
  ret = disk_read(lba2_buf, (LBA_t)lba1->partition_entries_lba, 1, card_type);

  // Load parition entries for the relevant boot partitions.
  partition_entries_t *fdt = (partition_entries_t *)(lba2_buf);
  partition_entries_t *opensbi = (partition_entries_t *)(lba2_buf + 128);
  partition_entries_t *kernel = (partition_entries_t *)(lba2_buf + 256);

  ret = disk_read((BYTE *)FDT_ADDRESS, fdt->first_lba, fdt->last_lba - fdt->first_lba + 1, card_type);
  ret = disk_read((BYTE *)OPENSBI_ADDRESS, opensbi->first_lba, opensbi->last_lba - opensbi->first_lba + 1, card_type);
  ret = disk_read((BYTE *)KERNEL_ADDRESS, kernel->first_lba,kernel->last_lba - kernel->first_lba + 1, card_type);

  return 0;
}

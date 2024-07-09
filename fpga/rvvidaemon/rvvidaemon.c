///////////////////////////////////////////
// rvvi daemon
//
// Written: Rose Thomposn ross1728@gmail.com
// Created: 31 May 2024
// Modified: 31 May 2024
//
// Purpose: Converts raw socket into rvvi interface to connect into ImperasDV
// 
// Documentation: 
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////


#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <linux/ip.h>
#include <linux/udp.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/ether.h>
#include "rvviApi.h" // *** bug fix me when this file gets included into the correct directory.
#include "idv/idv.h"


#define DEST_MAC0	0x43
#define DEST_MAC1	0x68
#define DEST_MAC2	0x11
#define DEST_MAC3	0x11
#define DEST_MAC4	0x02
#define DEST_MAC5	0x45

#define SRC_MAC0	0x54
#define SRC_MAC1	0x16
#define SRC_MAC2	0x00
#define SRC_MAC3	0x00
#define SRC_MAC4	0x54
#define SRC_MAC5	0x8F

#define BUF_SIZ		1024

//#define ETHER_TYPE	0x0801  // The type defined in packetizer.sv
#define ETHER_TYPE	0x5c00  // The type defined in packetizer.sv
//#define ETHER_TYPE	0x0000  // The type defined in packetizer.sv
#define DEFAULT_IF	"eno1"

FILE *VivadoPipeFP;
struct sockaddr_ll socket_address;
uint8_t sendbuf[BUF_SIZ];
struct ether_header *sendeh = (struct ether_header *) sendbuf;
int tx_len = 0;
int sockfd;

typedef struct {
  uint64_t PC;
  uint32_t insn;
  uint64_t Mcycle;
  uint64_t Minstret;
  uint8_t Trap : 1;
  uint8_t PrivilegeMode : 2;
  uint8_t GPREn : 1;
  uint8_t FPREn : 1;
  uint16_t CSRCount : 12;
  uint8_t GPRReg : 5;
  uint64_t GPRValue;
  uint8_t FPRReg : 5;
  uint64_t FPRValue;
  uint8_t CSRWen[3];
  uint16_t CSRReg[3];
  uint64_t CSRValue[3];
  
} RequiredRVVI_t; // total size is 241 bits or 30.125 bytes

typedef struct {
  uint8_t RegAddress : 5;
  uint64_t RegValue;
} Reg_t;

void DecodeRVVI(uint8_t *payload, ssize_t payloadsize, RequiredRVVI_t *InstructionData);
void BitShiftArray(uint8_t *dst, uint8_t *src, uint8_t ShiftAmount, int Length);
void PrintInstructionData(RequiredRVVI_t *InstructionData);
int ProcessRvviAll(RequiredRVVI_t *InstructionData);
void set_gpr(int hart, int reg, uint64_t value);
void set_fpr(int hart, int reg, uint64_t value);
int state_compare(int hart, uint64_t Minstret);

int main(int argc, char **argv){
  
  if(argc != 2){
    printf("Wrong number of arguments.\n");
    printf("rvvidaemon <ethernet device>\n");
    return -1;
  }

  // step 1 open a pipe to vivado
  /* if (( VivadoPipeFP = popen("vivado -mode tcl", "w")) == NULL){ */
  /*   perror("popen"); */
  /*   exit(1); */
  /* } */
  /* fputs("open_hw_manager\n", VivadoPipeFP); */
  /* fputs("connect_hw_server -url localhost:3121\n", VivadoPipeFP); */
  /* fputs("current_hw_target [get_hw_targets *\/xilinx_tcf/Digilent/\*]\n", VivadoPipeFP); */
  /* fputs("open_hw_target\n", VivadoPipeFP); */
  /* fputs("set_property PARAM.FREQUENCY 7500000 [get_hw_targets localhost:3121/xilinx_tcf/Digilent/210319B7CA87A]\n", VivadoPipeFP); */

  /* // *** bug these need to made relative paths. */
  /* fputs("set_property PROBES.FILE {/home/ross/repos/cvw/fpga/generator/WallyFPGA.runs/impl_1/fpgaTop.ltx} [get_hw_devices xc7a100t_0]\n", VivadoPipeFP); */
  /* fputs("set_property FULL_PROBES.FILE {/home/ross/repos/cvw/fpga/generator/WallyFPGA.runs/impl_1/fpgaTop.ltx} [get_hw_devices xc7a100t_0]\n", VivadoPipeFP); */
  /* fputs("set_property PROGRAM.FILE {/home/ross/repos/cvw/fpga/generator/WallyFPGA.runs/impl_1/fpgaTop.bit} [get_hw_devices xc7a100t_0]\n", VivadoPipeFP); */
  /* fputs("refresh_hw_device [lindex [get_hw_devices xc7a100t_0] 0]\n", VivadoPipeFP); */
  /* fputs("[get_hw_devices xc7a100t_0] -filter {CELL_NAME=~\"u_ila_0\"}]]\n", VivadoPipeFP); */
  
  uint8_t buf[BUF_SIZ];
  int sockopt;
  struct ifreq ifopts;	/* set promiscuous mode */
  struct ether_header *eh = (struct ether_header *) buf;
  ssize_t headerbytes, numbytes, payloadbytes;
  
  /* Open RAW socket to receive frames */
  if ((sockfd = socket(AF_PACKET, SOCK_RAW, htons(ETHER_TYPE))) == -1) {
    perror("socket");
  }
  printf("Here 0\n");

  /* Set interface to promiscuous mode - do we need to do this every time? */
  strncpy(ifopts.ifr_name, argv[1], IFNAMSIZ-1);
  ioctl(sockfd, SIOCGIFFLAGS, &ifopts);
  printf("Here 1\n");
  ifopts.ifr_flags |= IFF_PROMISC;
  ioctl(sockfd, SIOCSIFFLAGS, &ifopts);
  printf("Here 2\n");
  if (ioctl(sockfd, SIOCGIFINDEX, &ifopts) < 0)
    perror("SIOCGIFINDEX");
  
  /* Allow the socket to be reused - incase connection is closed prematurely */
  if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &sockopt, sizeof sockopt) == -1) {
    perror("setsockopt");
    close(sockfd);
    exit(EXIT_FAILURE);
  }
  printf("Here 3\n");
  
  /* Bind to device */
  if (setsockopt(sockfd, SOL_SOCKET, SO_BINDTODEVICE, argv[1], IFNAMSIZ-1) == -1)	{
    perror("SO_BINDTODEVICE");
    close(sockfd);
    exit(EXIT_FAILURE);
  }
  printf("Here 4\n");

  if(!rvviVersionCheck(RVVI_API_VERSION)){
    printf("Bad RVVI_API_VERSION\n");
  }

  /* Construct the Ethernet header */
  memset(sendbuf, 0, BUF_SIZ);
  /* Ethernet header */
  sendeh->ether_shost[0] = SRC_MAC0;
  sendeh->ether_shost[1] = SRC_MAC1;
  sendeh->ether_shost[2] = SRC_MAC2;
  sendeh->ether_shost[3] = SRC_MAC3;
  sendeh->ether_shost[4] = SRC_MAC4;
  sendeh->ether_shost[5] = SRC_MAC5;
  sendeh->ether_dhost[0] = DEST_MAC0;
  sendeh->ether_dhost[1] = DEST_MAC1;
  sendeh->ether_dhost[2] = DEST_MAC2;
  sendeh->ether_dhost[3] = DEST_MAC3;
  sendeh->ether_dhost[4] = DEST_MAC4;
  sendeh->ether_dhost[5] = DEST_MAC5;
  /* Ethertype field */
  //eh->ether_type = htons(ETH_P_IP);
  sendeh->ether_type = htons(ETHER_TYPE);
  tx_len += sizeof(struct ether_header);
  /* Packet data */
  sendbuf[tx_len++] = 0xde;
  sendbuf[tx_len++] = 0xad;
  sendbuf[tx_len++] = 0xbe;
  sendbuf[tx_len++] = 0xef;

  rvviRefConfigSetString(IDV_CONFIG_MODEL_VENDOR, "riscv.ovpworld.org");
  rvviRefConfigSetString(IDV_CONFIG_MODEL_NAME,"riscv");
  rvviRefConfigSetString(IDV_CONFIG_MODEL_VARIANT, "RV64GC");
  rvviRefConfigSetInt(IDV_CONFIG_MODEL_ADDRESS_BUS_WIDTH, 56);
  rvviRefConfigSetInt(IDV_CONFIG_MAX_NET_LATENCY_RETIREMENTS, 6);

  /* Index of the network device */
  socket_address.sll_ifindex = ifopts.ifr_ifindex;
  /* Address length*/
  socket_address.sll_halen = ETH_ALEN;
  /* Destination MAC */
  socket_address.sll_addr[0] = DEST_MAC0;
  socket_address.sll_addr[1] = DEST_MAC1;
  socket_address.sll_addr[2] = DEST_MAC2;
  socket_address.sll_addr[3] = DEST_MAC3;
  socket_address.sll_addr[4] = DEST_MAC4;
  socket_address.sll_addr[5] = DEST_MAC5;

  int i;
  printf("buffer: ");
  for(i=0;i<tx_len;i++){
    printf("%02hhx ", sendbuf[i]);
  }
  printf("\n");
  printf("sockfd %x\n", sockfd);

  // eventually we want to put the elffiles here
  rvviRefInit(NULL);
  rvviRefPcSet(0, 0x1000);
  
  // Volatile CSRs
  rvviRefCsrSetVolatile(0, 0xC00);   // CYCLE
  rvviRefCsrSetVolatile(0, 0xB00);   // MCYCLE
  rvviRefCsrSetVolatile(0, 0xC02);   // INSTRET
  rvviRefCsrSetVolatile(0, 0xB02);   // MINSTRET
  rvviRefCsrSetVolatile(0, 0xC01);   // TIME

  int iter;
  for (iter = 0xC03; iter <= 0xC1F; iter++) {
    rvviRefCsrSetVolatile(0, iter);   // HPMCOUNTERx
  }
  // Machine MHPMCOUNTER3 - MHPMCOUNTER31
  for (iter = 0xB03; iter <= 0xB1F; iter++) {
    rvviRefCsrSetVolatile(0, iter);   // MHPMCOUNTERx
  }
  // cannot predict this register due to latency between
  // pending and taken
  rvviRefCsrSetVolatile(0, 0x344);   // MIP
  rvviRefCsrSetVolatile(0, 0x144);   // SIP

  // set bootrom and bootram as volatile memory
  rvviRefMemorySetVolatile(0x1000, 0x1FFF);
  rvviRefMemorySetVolatile(0x2000, 0x2FFF);

  // Privileges for PMA are set in the imperas.ic
  // volatile (IO) regions are defined here
  // only real ROM/RAM areas are BOOTROM and UNCORE_RAM
  rvviRefMemorySetVolatile(0x2000000, 0x2000000 + 0xFFFF);
  rvviRefMemorySetVolatile(0x10060000, 0x10060000 + 0xFF);
  rvviRefMemorySetVolatile(0x10000000, 0x10000000 + 0x7);
  rvviRefMemorySetVolatile(0x0C000000, 0x0C000000 + 0x03FFFFFF);
  rvviRefMemorySetVolatile(0x00013000, 0x00013000 + 0x7F);
  rvviRefMemorySetVolatile(0x10040000, 0x10040000 + 0xFFF);

  while(1) {
    //printf("listener: Waiting to recvfrom...\n");
    numbytes = recvfrom(sockfd, buf, BUF_SIZ, 0, NULL, NULL);
    headerbytes = (sizeof(struct ether_header));
    payloadbytes = numbytes - headerbytes;
    int result;
    //printf("listener: got frame %lu bytes\n", numbytes);
    //printf("payload size: %lu bytes\n", payloadbytes);
    if (eh->ether_dhost[0] == DEST_MAC0 &&
        eh->ether_dhost[1] == DEST_MAC1 &&
        eh->ether_dhost[2] == DEST_MAC2 &&
        eh->ether_dhost[3] == DEST_MAC3 &&
        eh->ether_dhost[4] == DEST_MAC4 &&
        eh->ether_dhost[5] == DEST_MAC5) {
      //printf("Correct destination MAC address\n");
      uint64_t PC;
      uint32_t insn;
      RequiredRVVI_t InstructionData;
      DecodeRVVI(buf + headerbytes, payloadbytes, &InstructionData);
      // now let's drive IDV
      // start simple just drive and compare PC.
      PrintInstructionData(&InstructionData);
      result = ProcessRvviAll(&InstructionData);
      if(result == -1) break;
    }
  }

  printf("Simulation halted due to mismatch\n");

  //pclose(VivadoPipeFP);
  close(sockfd);

  

  return 0;
}

int ProcessRvviAll(RequiredRVVI_t *InstructionData){
  long int found;
  uint64_t time = InstructionData->Mcycle;
  uint8_t trap = InstructionData->Trap;
  uint64_t order = InstructionData->Minstret;
  int result;

  result = 0;
  if(InstructionData->GPREn) set_gpr(0, InstructionData->GPRReg, InstructionData->GPRValue);
  if(InstructionData->FPREn) set_fpr(0, InstructionData->FPRReg, InstructionData->FPRValue);

  if (trap) {
    rvviDutTrap(0, InstructionData->PC, InstructionData->insn);
  } else {
    rvviDutRetire(0, InstructionData->PC, InstructionData->insn, 0);
  }

  if(!trap) result = state_compare(0, InstructionData->Minstret);
  // *** set is for nets like interrupts  come back to this.
  //found = rvviRefNetIndexGet("pc_rdata");
  //rvviRefNetSet(found, InstructionData->PC, time);
  return result;
  
}

int state_compare(int hart, uint64_t Minstret){
  uint8_t result = 1;
  uint8_t stepOk = 0;
  char buf[80];
  rvviDutCycleCountSet(Minstret);
  if(rvviRefEventStep(hart) != 0) {
    stepOk = 1;
    result &= rvviRefPcCompare(hart);
    result &= rvviRefInsBinCompare(hart);
    result &= rvviRefGprsCompare(hart);
    result &= rvviRefFprsCompare(hart);
    //result &= rvviRefCsrCompare(hart);
  } else {
    result = 0;
  }

  if (result == 0) {
    /* Send packet */
    if (sendto(sockfd, sendbuf, tx_len, 0, (struct sockaddr*)&socket_address, sizeof(struct sockaddr_ll)) < 0){
      printf("Send failed\n");
    }else {
      printf("send success!\n");
    }

    sprintf(buf, "MISMATCH @ instruction # %ld\n", Minstret);
    idvMsgError(buf);
    /* fputs("run_hw_ila [get_hw_ilas -of_objects [get_hw_devices xc7a100t_0] -filter {CELL_NAME=~\"u_ila_0\"}] -trigger_now\n", VivadoPipeFP); */
    /* fputs("current_hw_ila_data [upload_hw_ila_data hw_ila_1]\n", VivadoPipeFP); */
    /* fputs("display_hw_ila_data [current_hw_ila_data]\n", VivadoPipeFP); */
    /* fputs("write_hw_ila_data my_hw_ila_data [current_hw_ila_data]\n", VivadoPipeFP); */
    return -1;
    //if (ON_MISMATCH_DUMP_STATE) dump_state(hart);
  }
  
}

void set_gpr(int hart, int reg, uint64_t value){
  rvviDutGprSet(hart, reg, value);
}

void set_fpr(int hart, int reg, uint64_t value){
  rvviDutFprSet(hart, reg, value);
}

void DecodeRVVI(uint8_t *payload, ssize_t payloadsize, RequiredRVVI_t *InstructionData){
  // you know this actually easiser in assembly. :(
  uint8_t buf2[BUF_SIZ], buf3[BUF_SIZ];
  uint8_t * buf2ptr, *buf3ptr;
  buf2ptr = buf2;
  buf3ptr = buf3;
  //int PayloadSize = sizeof(RequiredRVVI_t) - 1;
  int PayloadSize = 30;
  int Buf2Size = BUF_SIZ - PayloadSize;
  uint64_t Mcycle, Minstret;
  uint64_t PC;
  uint32_t insn;
  // unforunately the struct appoarch does not work?!?
  PC = * (uint64_t *) payload;
  payload += 8;
  insn = * (uint32_t *) payload;
  payload += 4;
  Mcycle = * (uint64_t *) payload;
  payload += 8;
  Minstret = * (uint64_t *) payload;
  payload += 8;
  // the next 4 bytes contain CSRCount (12), FPRWen(1), GPRWen(1), PrivilegeMode(2), Trap(1)
  uint32_t RequiredFlags;
  RequiredFlags = * (uint32_t *) payload;
  uint8_t Trap, PrivilegeMode, GPRWen, FPRWen;
  uint16_t CSRCount = 0;
  uint8_t GPRReg = 0;
  uint64_t GPRData = 0;
  uint8_t FPRReg = 0;
  uint64_t FPRData = 0;
  uint8_t CSRWen[3] = {0, 0, 0};
  uint16_t CSRReg[3];
  uint64_t CSRValue[3];
  int CSRIndex;

  Trap = RequiredFlags & 0x1;
  PrivilegeMode = (RequiredFlags >> 1) & 0x3;
  GPRWen = (RequiredFlags >> 3) & 0x1;
  FPRWen = (RequiredFlags >> 4) & 0x1;
  CSRCount = (RequiredFlags >> 5) & 0xFFF;
  payload += 2;

  if(GPRWen || FPRWen || (CSRCount != 0)){
    // the first bit of payload is the last bit of CSRCount.
    ssize_t newPayloadSize = payloadsize - 30;
    BitShiftArray(buf2, payload, 1, newPayloadSize);
    int index;
    if(GPRWen){
      GPRReg = * (uint8_t *) buf2ptr;
      GPRReg = GPRReg & 0x1F;
      BitShiftArray(buf3, buf2ptr, 5, newPayloadSize);
      GPRData = * (uint64_t *) buf3;
      if(FPRWen){
	buf3ptr += 8;
	FPRReg = * (uint8_t *) buf3ptr;
	BitShiftArray(buf2, buf3ptr, 5, newPayloadSize - 8);
	FPRReg = FPRReg & 0x1F;
	FPRData = * (uint64_t *) buf2;
      }
    }else if(FPRWen){
      FPRReg = * (uint8_t *) buf2;
      FPRReg = FPRReg & 0x1F;
      BitShiftArray(buf3, buf2, 5, newPayloadSize);
      FPRData = * (uint64_t *) buf3;
    }
    if(GPRWen ^ FPRWen){
      payload += 8;
      Buf2Size = payloadsize - 38;
      BitShiftArray(buf2, payload, 6, Buf2Size);
    }else if(GPRWen & FPRWen){
      payload += 17;
      Buf2Size = payloadsize - 47;
      BitShiftArray(buf2, payload, 3, Buf2Size);
    }else{
      Buf2Size = payloadsize - 30;
      BitShiftArray(buf2, payload, 1, Buf2Size);
    }
    buf2ptr = buf2;
    for(CSRIndex = 0; CSRIndex < CSRCount; CSRIndex++){
      CSRReg[CSRIndex] = (*(uint16_t *) buf2ptr) & 0xFFF;
      Buf2Size -= 1;
      BitShiftArray(buf3, buf2ptr + 1, 4, Buf2Size);
      CSRValue[CSRIndex] = (*(uint64_t *) buf3);
      CSRWen[CSRIndex] = 1;
      buf2ptr = buf3;
    }
  }
  InstructionData->PC = PC;
  InstructionData->insn = insn;
  InstructionData->Mcycle = Mcycle;
  InstructionData->Minstret = Minstret;
  InstructionData->Trap = Trap;
  InstructionData->PrivilegeMode = PrivilegeMode;
  InstructionData->GPREn = GPRWen;
  InstructionData->FPREn = FPRWen;
  InstructionData->CSRCount = CSRCount;
  InstructionData->GPRReg = GPRReg;
  InstructionData->GPRValue = GPRData;
  InstructionData->FPRReg = FPRReg;
  InstructionData->FPRValue = FPRData;
  for(CSRIndex = 0; CSRIndex < 3; CSRIndex++){
    InstructionData->CSRWen[CSRIndex] = CSRWen[CSRIndex];
    InstructionData->CSRReg[CSRIndex] = CSRReg[CSRIndex];
    InstructionData->CSRValue[CSRIndex] = CSRValue[CSRIndex];
  }
}

void PrintInstructionData(RequiredRVVI_t *InstructionData){
  int CSRIndex;
  printf("PC = %lx, insn = %x, Mcycle = %lx, Minstret = %lx, Trap = %hhx, PrivilegeMode = %hhx",
	 InstructionData->PC, InstructionData->insn, InstructionData->Mcycle, InstructionData->Minstret, InstructionData->Trap, InstructionData->PrivilegeMode);
  if(InstructionData->GPREn){
    printf(", GPR[%d] = %lx", InstructionData->GPRReg, InstructionData->GPRValue);
  }
  if(InstructionData->FPREn){
    printf(", FPR[%d] = %lx", InstructionData->FPRReg, InstructionData->FPRValue);
  }
  for(CSRIndex = 0; CSRIndex < 3; CSRIndex++){
    if(InstructionData->CSRWen[CSRIndex]){
      printf(", CSR[%x] = %lx", InstructionData->CSRReg[CSRIndex], InstructionData->CSRValue[CSRIndex]);
    }
  }
  printf("\n");
}

void BitShiftArray(uint8_t *dst, uint8_t *src, uint8_t ShiftAmount, int Length){
  // always shift right by ShiftAmount (0 to 7 bit positions).
  // *** this implemenation is very inefficient. improve later.
  if(ShiftAmount < 0 || ShiftAmount > 7) return;
  /* Read the first source byte
     Read the second source byte
     Right Shift byte 1 by ShiftAmount
     Right Rotate byte 2 by ShiftAmount
     Mask byte 2 by ~(2^ShiftAmount -1)
     OR together the two bytes to form the final next byte

     repeat this for each byte
     On the last byte we don't do the last steps
   */
  int Index;
  for(Index = 0; Index < Length - 1; Index++){
    uint8_t byte1 = src[Index];
    uint8_t byte2 = src[Index+1];
    byte1 = byte1 >> ShiftAmount;
    uint8_t byte2rot = (byte2 << (unsigned) (8 - ShiftAmount)) & 0xff;
    uint8_t byte1final = byte2rot | byte1;
    dst[Index] = byte1final;
  }
  // fence post
  // For last one there is only one source byte
  uint8_t byte1 = src[Length-1];
  byte1 = byte1 >> ShiftAmount;
  dst[Length-1] = byte1;
}

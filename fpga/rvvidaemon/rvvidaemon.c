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
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/ether.h>


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

void DecodeRVVI(uint8_t *payload, uint64_t * PC, uint32_t *insn);

int main(int argc, char **argv){
  
  if(argc != 2){
    printf("Wrong number of arguments.\n");
    printf("rvvidaemon <ethernet device>\n");
    return -1;
  }

  char sender[INET6_ADDRSTRLEN];
  int sockfd;
  struct ifreq if_idx;
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

  while(1) {
    printf("listener: Waiting to recvfrom...\n");
    numbytes = recvfrom(sockfd, buf, BUF_SIZ, 0, NULL, NULL);
    headerbytes = (sizeof(struct ether_header));
    payloadbytes = numbytes - headerbytes;
    printf("listener: got frame %lu bytes\n", numbytes);
    printf("payload size: %lu bytes\n", payloadbytes);
    if (eh->ether_dhost[0] == DEST_MAC0 &&
        eh->ether_dhost[1] == DEST_MAC1 &&
        eh->ether_dhost[2] == DEST_MAC2 &&
        eh->ether_dhost[3] == DEST_MAC3 &&
        eh->ether_dhost[4] == DEST_MAC4 &&
        eh->ether_dhost[5] == DEST_MAC5) {
      printf("Correct destination MAC address\n");
      uint64_t PC;
      uint32_t insn;
      DecodeRVVI(buf + headerbytes, &PC, &insn);
      printf("PC = %lx, insn = %x\n", PC, insn);
    }
  }

  close(sockfd);

  return 0;
}

void DecodeRVVI(uint8_t *payload, uint64_t * PC, uint32_t *insn){
  // you know this actually easiser in assembly. :(
  *PC = *((uint64_t *) payload);
  *insn = *((uint32_t *) (payload + 8));
}

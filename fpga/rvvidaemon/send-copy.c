
/*
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 */

#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/ether.h>
#include <unistd.h>

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

#define DEFAULT_IF	"eth0"
#define BUF_SIZ		1024
#define ETHER_TYPE	0x5c00  // The type defined in packetizer.sv

int main(int argc, char *argv[])
{
	int sockfd;
	struct ifreq if_idx;
	struct ifreq if_mac;
	int tx_len = 0;
	char sendbuf[BUF_SIZ];
	struct ether_header *eh = (struct ether_header *) sendbuf;
	struct iphdr *iph = (struct iphdr *) (sendbuf + sizeof(struct ether_header));
	struct sockaddr_ll socket_address;
	char ifName[IFNAMSIZ];
	
	/* Get interface name */
	if (argc > 1)
		strcpy(ifName, argv[1]);
	else
		strcpy(ifName, DEFAULT_IF);

	/* Open RAW socket to send on */
	//if ((sockfd = socket(AF_PACKET, SOCK_RAW, IPPROTO_RAW)) == -1) {
	if ((sockfd = socket(AF_PACKET, SOCK_RAW, htons(ETHER_TYPE))) == -1) {
	    perror("socket");
	}

	/* Get the index of the interface to send on */
	memset(&if_idx, 0, sizeof(struct ifreq));
	strncpy(if_idx.ifr_name, ifName, IFNAMSIZ-1);
	if (ioctl(sockfd, SIOCGIFINDEX, &if_idx) < 0)
	    perror("SIOCGIFINDEX");
	/* Get the MAC address of the interface to send on */
	memset(&if_mac, 0, sizeof(struct ifreq));
	strncpy(if_mac.ifr_name, ifName, IFNAMSIZ-1);
	if (ioctl(sockfd, SIOCGIFHWADDR, &if_mac) < 0)
	    perror("SIOCGIFHWADDR");

	/* Construct the Ethernet header */
	memset(sendbuf, 0, BUF_SIZ);
	/* Ethernet header */
	/* eh->ether_shost[0] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[0]; */
	/* eh->ether_shost[1] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[1]; */
	/* eh->ether_shost[2] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[2]; */
	/* eh->ether_shost[3] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[3]; */
	/* eh->ether_shost[4] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[4]; */
	/* eh->ether_shost[5] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[5]; */
	eh->ether_shost[0] = SRC_MAC0;
	eh->ether_shost[1] = SRC_MAC1;
	eh->ether_shost[2] = SRC_MAC2;
	eh->ether_shost[3] = SRC_MAC3;
	eh->ether_shost[4] = SRC_MAC4;
	eh->ether_shost[5] = SRC_MAC5;
	eh->ether_dhost[0] = DEST_MAC0;
	eh->ether_dhost[1] = DEST_MAC1;
	eh->ether_dhost[2] = DEST_MAC2;
	eh->ether_dhost[3] = DEST_MAC3;
	eh->ether_dhost[4] = DEST_MAC4;
	eh->ether_dhost[5] = DEST_MAC5;
	/* Ethertype field */
	//eh->ether_type = htons(ETH_P_IP);
	eh->ether_type = htons(ETHER_TYPE);
	tx_len += sizeof(struct ether_header);

	/* Packet data */
	sendbuf[tx_len++] = 0xde;
	sendbuf[tx_len++] = 0xad;
	sendbuf[tx_len++] = 0xbe;
	sendbuf[tx_len++] = 0xef;

	/* Index of the network device */
	socket_address.sll_ifindex = if_idx.ifr_ifindex;
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

	/* Send packet */
	if (sendto(sockfd, sendbuf, tx_len, 0, (struct sockaddr*)&socket_address, sizeof(struct sockaddr_ll)) < 0){
	    printf("Send failed\n");
	}else {
	printf("send success!\n");
	}
	close(sockfd);
	return 0;
}

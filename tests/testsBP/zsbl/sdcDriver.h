#ifndef __SDCDRIVER_H
#define __SDCDRIVER_H


void copySDC512(long int, long int *);
volatile void waitInitSDC();
void setSDCCLK(int);
void copyFlash(long int, long int *, int);

#endif

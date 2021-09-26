///////////////////////////////////////////
// SDC.sv
//
// Written: Ross Thompson September 25, 2021
// Modified: 
//
// Purpose: driver for sdc reader.
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////


#include "sdcDriver.h"

#define SDC_MAIL_BOX 0x12100

void copySDC512(long int blockAddr, long int * Dst) {

  waitInitSDC();

  volatile long int * mailBoxAddr;
  volatile int * mailBoxCmd;
  volatile int * mailBoxStatus;
  volatile long int * mailBoxReadData;
  mailBoxStatus = (int *) (SDC_MAIL_BOX + 0x4);  
  mailBoxCmd = (int *) (SDC_MAIL_BOX + 0x8);
  mailBoxAddr = (long int *) (SDC_MAIL_BOX + 0x10);
  mailBoxReadData = (long int *) (SDC_MAIL_BOX + 0x18);  
  
  // write the SDC address register with the blockAddr
  *mailBoxAddr = blockAddr;
  *mailBoxCmd = 0x4;

  // wait until the mailbox has valid data
  // this occurs when status[1] = 0
  while((*mailBoxStatus & 0x2) == 0x2);

  int index;
  for(index = 0; index < 512/8; index++) {
    Dst[index] = *mailBoxReadData;
  }
}

volatile void waitInitSDC(){
  volatile int * mailBoxStatus;
  mailBoxStatus = (int *) (SDC_MAIL_BOX + 0x4);
  while((*mailBoxStatus & 0x1) != 0x1);
}

void setSDCCLK(int divider){
  volatile int * mailBoxCLK;
  mailBoxCLK = (int *) (SDC_MAIL_BOX + 0x0);
  *mailBoxCLK = divider;
}

// main.c
// C Runtime entry point
// James Kaden Cassidy
// kacassidy@hmc.edu
// 12/19/2025

extern void partial_load_store_test(void);
extern void micro_test(void);
extern void sendstring_like_test(void);
extern void partial_load_test(void);
extern void hazard_test(void);
extern void end(void);
extern void loop_copy_test(void);

void _send_char(char c) {
  /*#error "You must implement the method _send_char to use this file!\n";
  */
  volatile unsigned char *THR=(unsigned char *)0x10000000;
  volatile unsigned char *LSR=(unsigned char *)0x10000005;

  while(!(*LSR&0b100000));
  *THR=c;
  while(!(*LSR&0b100000));
}

int sendstring(const char *p){
  int n=0;
  while (*p) {
    _send_char(*p);
    n++;
    p++;
  }

  return n;
}

void print_check() {
  sendstring("Check\n");
}

int main(void) {
    sendstring("Hello World\n");
    end();         // never returns
    return 0;      // unreachable, but keeps compilers happy
}

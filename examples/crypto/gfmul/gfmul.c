// gfmul.c - Galois Field multiplication
// James Stine and David Harris 16 May 2024

#include <stdio.h>

/* return ab mod m(x) - long multiplication in GF(2^n) with polynomial m */
int gfmul(int a, int b, int n, int m) {
   int result = 0;
   while (b) {
     if (b & 1) result = result ^ a; /* if bit of b is set add a */
     a = a << 1;                     /* multiply a by x */
     if (a & 1 << n)
       a = a ^ m;                    /* reduce/sub modulo AES m(x) = 100011011 */
     //printf("a = %x, b = %x, result = %x\n", a, b, result);
     b = b >> 1;                     /* get next bit of b */
   }
   return result;
}

void inverses(void) {
    int i, j, k, num;

    printf("\nTable of inverses in GF(2^8) with polynomial m(x) = 100011011\n");
    for (i=0; i<16; i++) {
        for (j=0; j<16; j++) {
            num = i*16+j;
            if (num ==0) printf ("00 ");
            else for (k=1; k<256; k++) {
                if (gfmul(num, k, 8, 0b100011011) == 1) {
                    printf("%02x ", k);
                    break;
                }
            }
        }
        printf("\n");
    }
}

void inverses3(void) {
    int k, num;

    printf("\nTable of inverses in GF(2^8) with polynomial m(x) = 100011011\n");
    for (num=0; num<8; num++) {
        if (num == 0) printf ("0 ");
        else for (k=1; k<8; k++) {
            if (gfmul(num, k, 3, 0b1011) == 1) {
                printf("%d ", k);
                break;
            }
        }
    }
    printf("\n");
}


int main() {
  int a = 0xC5;
  int b = 0xA1;

  printf("The GF(2^8) result is %x\n", gfmul(a,b, 8, 0b100011011));
  printf("The GF(2^8) result is %x\n", gfmul(0xC1, 0x28, 8, 0b100011011));
  inverses();

  // tabulate inverses for GF(2^3)
  inverses3();
  // check worked examples
    printf("The GF(2^3) result is %d\n", gfmul(0b101,0b011, 3, 0b1011));
    printf("The GF(2^3) result is %d\n", gfmul(0b101,0b010, 3, 0b1011));
    printf("The GF(2^3) result is %d\n", gfmul(0b101,0b100, 3, 0b1011));
    printf("The GF(2^3) result is %d\n", gfmul(0b101,0b011, 3, 0b1011));
 
}

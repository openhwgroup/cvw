#include <stdio.h>  // supports printf
int main(void) {
	int a = 3;
	int b = 4;
	int c;
	// compute c = a + 2*b using inline assembly
	asm volatile("slli %0, %1, 1" : "=r" (c) : "r" (b));	      // c = b << 1
	asm volatile("add %0, %1, %2" : "=r" (c) : "r" (a), "r" (c)); // c = a + c

	printf("c = %d\n", c);
}

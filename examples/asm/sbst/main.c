#include "tests.h"


const signature_t const GOLDEN_SIGNATURES[NUMTESTS] = {
	0xCAFECAFE,	// TEST1
};

int main(void)
{
	int i, fails;
	signature_t signatures[NUMTESTS];
	
	signatures[TEST1] = test1();

	for(i=0; i<NUMTESTS; i++) {
		fails += signatures[i] != GOLDEN_SIGNATURES[i];
	}

 	return fails;
}
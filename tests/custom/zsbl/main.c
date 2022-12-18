#include "uart.h"
#include "sdcDriver.h"
#include "gpt.h"

int main()
{
    init_uart(30000000, 115200);
    print_uart("Hello World!\r\n");

    int res = gpt_find_boot_partition((long int *)0x80000000UL, 2 * 16384);

    if (res == 0)
    {
      return 0;
    }

    while (1)
    {
        // do nothing
    }
}

void handle_trap(void)
{
    // print_uart("trap\r\n");
}

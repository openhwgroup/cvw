#include <stdlib.h>

#include "Vtestbench__Dpi.h"

const char *getenvval(const char *pszName) {
    return ((const char *) getenv(pszName));
}
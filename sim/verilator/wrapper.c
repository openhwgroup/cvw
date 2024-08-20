#include <stdlib.h>

#include "Vtestbench__Dpi.h"

const char *getenvval(const char *pszName) {
    const char *pszValue = getenv(pszName);
    if (pszValue == NULL) {
        return "";
    }
    return ((const char *) getenv(pszName));
}
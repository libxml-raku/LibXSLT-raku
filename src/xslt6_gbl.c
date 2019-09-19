#include "xslt6.h"
#include "xslt6_gbl.h"

DLLEXPORT int xslt6_gbl_have_exslt(void) {
#ifdef XSLT6_HAVE_EXSLT
    return 1;
#else
    return 0;
#endif
}




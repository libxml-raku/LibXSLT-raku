#include "xslt6.h"
#include "xslt6_config.h"
#include "libxslt/xsltconfig.h"

DLLEXPORT int xslt6_config_have_exslt(void) {
    return
#ifdef XSLT6_HAVE_EXSLT
    1
#else
    0
#endif
    ;
}

DLLEXPORT char* xslt6_config_version(void) {
    return LIBXSLT_DOTTED_VERSION;
}

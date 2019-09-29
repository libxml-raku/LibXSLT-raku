#include "xslt6.h"
#include "xslt6_gbl.h"

#include "libxslt/xslt.h"

DLLEXPORT void xslt6_gbl_set_max_depth(int val) {
    xsltMaxDepth = val;
}

DLLEXPORT void xslt6_gbl_set_max_vars(int val) {
    xsltMaxVars = val;
}




#include "xslt6.h"
#include "xslt6_stylesheet.h"
#include <string.h>
#include <assert.h>

DLLEXPORT void
xslt6_transform_ctx_set_xinclude(xsltTransformContextPtr self, int xinc) {
    assert(self != NULL);
    self->xinclude = xinc;
}

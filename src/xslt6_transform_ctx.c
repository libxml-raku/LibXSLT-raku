#include "xslt6.h"
#include "xslt6_stylesheet.h"
#include <string.h>
#include <assert.h>

DLLEXPORT void
xslt6_transform_ctx_set_xinclude(xsltTransformContextPtr self, int xinc) {
    assert(self != NULL);
    self->xinclude = xinc;
}

DLLEXPORT xmlNodePtr
xslt6_transform_ctx_get_insert_node(xsltTransformContextPtr self) {
    assert(self != NULL);
    return self->insert;
}

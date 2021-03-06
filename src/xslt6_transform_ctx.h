#ifndef __XSLT6_TRANFORM_CTX_H
#define __XSLT6_TRANFORM_CTX_H

#include <libxslt/xsltInternals.h>
#include <libxslt/imports.h>

DLLEXPORT void
xslt6_transform_ctx_set_xinclude(xsltTransformContextPtr, int);

DLLEXPORT xmlNodePtr
xslt6_transform_ctx_get_insert_node(xsltTransformContextPtr self);y

#endif /* __XSLT6_TRANFORM_CTX_H */

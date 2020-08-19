#ifndef __XSLT6_STYLESHEET_H
#define __XSLT6_STYLESHEET_H

#include <libxslt/xsltInternals.h>
#include <libxslt/imports.h>
#include <libxslt/transform.h>

DLLEXPORT xmlDocPtr
xslt6_stylesheet_transform(xsltStylesheetPtr, xmlDocPtr, xsltTransformContextPtr, const char**);

DLLEXPORT xmlChar*
xslt6_stylesheet_media_type(xsltStylesheetPtr);

DLLEXPORT xmlChar*
xslt6_stylesheet_output_method(xsltStylesheetPtr);

#endif /* __XSLT6_STYLESHEET_H */

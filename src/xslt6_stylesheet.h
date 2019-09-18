#ifndef __XSLT6_STYLESHEET_H
#define __XSLT6_STYLESHEET_H

#include <libxslt/xsltInternals.h>
#include <libxslt/imports.h>

DLLEXPORT xmlChar*
xslt6_stylesheet_media_type(xsltStylesheetPtr self);

DLLEXPORT xmlChar*
xslt6_stylesheet_output_method(xsltStylesheetPtr self);

#endif /* __XSLT6_STYLESHEET_H */

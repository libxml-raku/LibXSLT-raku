#include "xslt6.h"
#include "xslt6_stylesheet.h"
#include <string.h>
#include <assert.h>


DLLEXPORT xmlChar*
xslt6_stylesheet_media_type(xsltStylesheetPtr self) {
    xmlChar *mediaType;
    xmlChar *method;
    const char *rv;

    XSLT_GET_IMPORT_PTR(mediaType, self, mediaType);

    if (mediaType == NULL) {
        XSLT_GET_IMPORT_PTR(method, self, method);
        rv = "text/xml";
        /* this below is rather simplistic, but should work for most cases */
        if (method != NULL) {
            if (xmlStrcmp(method, (xmlChar*) "html") == 0) {
                rv = "text/html";
            }
            else if (xmlStrcmp(method, (xmlChar*) "text") == 0) {
                rv = "text/plain";
            }
        }
    }
    else {
        rv = (char*) mediaType;
    }
    return xmlStrdup(rv);
}

DLLEXPORT xmlChar*
xslt6_stylesheet_output_method(xsltStylesheetPtr self) {
    xmlChar *method;
    const char *rv;
    XSLT_GET_IMPORT_PTR(method, self, method);

    rv = (char*) method;
    if (rv == NULL) {
        /* read http://www.w3.org/TR/xslt#output and tell me how
           you'd implement this the way it says to. */
        rv = "xml";
    }
    return xmlStrdup(rv);
}

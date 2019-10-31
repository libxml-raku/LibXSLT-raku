#include "xslt6.h"
#include "xslt6_stylesheet.h"
#include <string.h>
#include <assert.h>

DLLEXPORT xmlDocPtr
xslt6_stylesheet_transform(xsltStylesheetPtr self, xmlDocPtr doc, xsltTransformContextPtr ctx, const char** xslt_params) {
    xmlDocPtr real_dom;
    xmlNodePtr dtd_prev = NULL;
    xmlNodePtr dtd_next = NULL;

    if (self == NULL || doc == NULL || ctx == NULL) {
        return NULL;
    }
    if (doc->intSubset != NULL) {
	  /* Note: libxslt will unlink intSubset, we
	     want to restore it when done
	   */
          dtd_prev = doc->intSubset->prev;
          dtd_next = doc->intSubset->next;
    }

    real_dom = xsltApplyStylesheetUser(self, doc, xslt_params,
					   NULL, NULL, ctx);
    if (doc->intSubset != NULL &&
        doc->prev == NULL && doc->next == NULL) {
        xmlNodePtr cur = (xmlNodePtr) doc->intSubset;
        cur->prev = dtd_prev;
        cur->next = dtd_next;
        if (dtd_prev) dtd_prev->next = cur;
        if (dtd_next) dtd_next->prev = cur;
        if (doc->children == dtd_next) doc->children = cur;
        if (doc->last == dtd_prev) doc->last = cur;
    }
    if ((real_dom != NULL) && (ctx->state != XSLT_STATE_OK)) {
        /* fatal error */
        xmlFreeDoc(real_dom);
        real_dom = NULL;
    }
    if (real_dom != NULL && real_dom->type == XML_HTML_DOCUMENT_NODE) {
        if (self->method != NULL) {
            xmlFree(self->method);
        }
        self->method = (xmlChar *) xmlMalloc(5);
        strcpy((char *) self->method, "html");
    }
    return real_dom;
}

DLLEXPORT xmlChar*
xslt6_stylesheet_media_type(xsltStylesheetPtr self) {
    xmlChar *mediaType;
    xmlChar *method;
    const char *rv;

    XSLT_GET_IMPORT_PTR(mediaType, self, mediaType);
    rv = (char*) mediaType;
    return xmlStrdup(rv);
}

DLLEXPORT xmlChar*
xslt6_stylesheet_output_method(xsltStylesheetPtr self) {
    xmlChar *method;
    const char *rv;
    XSLT_GET_IMPORT_PTR(method, self, method);
    rv = (char*) method;
    return xmlStrdup(rv);
}

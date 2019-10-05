#ifndef __XSLT6_GBL_H
#define __XSLT6_GBL_H

DLLEXPORT void xslt6_gbl_set_max_depth(int val);
DLLEXPORT void xslt6_gbl_set_max_vars(int val);

typedef void (*xslt6_gbl_DebugFunc) (const char *msg,
                                     const char *argt,
                                     ...);

#endif /* __XSLT6_GBL_H */

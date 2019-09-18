#ifndef __XSLT6_H
#define __XSLT6_H

#ifdef _WIN32
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT extern
#endif

#define xslt6_warn(msg) fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, (msg));
#define xslt6_fail(msg) {xslt6_warn(msg);return;}

#endif /* __XSLT6_H */

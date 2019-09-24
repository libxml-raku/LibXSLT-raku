use v6;
unit module LibXSLT::Enums;

enum xsltSecurityOption is export (
    XSLT_SECPREF_CREATE_DIRECTORY => 3,
    XSLT_SECPREF_READ_FILE => 1,
    XSLT_SECPREF_READ_NETWORK => 4,
    XSLT_SECPREF_WRITE_FILE => 2,
    XSLT_SECPREF_WRITE_NETWORK => 5,
);

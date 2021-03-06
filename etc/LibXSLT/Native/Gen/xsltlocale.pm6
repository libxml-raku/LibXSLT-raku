use v6;
#  -- DO NOT EDIT --
# generated by: ../LibXML-p6/etc/generator.p6 --mod=LibXSLT --lib=XSLT etc/libxslt-api.xml

unit module LibXSLT::Native::Gen::xsltlocale;
# Locale handling:
#    Interfaces for locale handling. Needed for language dependent sorting. 
use LibXML::Native::Defs :xmlCharP;
use LibXSLT::Native::Defs :$lib;

our sub xsltFreeLocale(xsltLocale $locale) is native(XSLT) is export {*}
our sub xsltFreeLocales() is native(XSLT) is export {*}
our sub xsltLocaleStrcmp(xsltLocale $locale, const xsltLocaleChar * $str1, const xsltLocaleChar * $str2 --> int32) is native(XSLT) is export {*}
our sub New(xmlCharP $languageTag --> xsltLocale) is native(XSLT) is symbol('xsltNewLocale') {*}
our sub xsltStrxfrm(xsltLocale $locale, xmlCharP $string --> xsltLocaleChar *) is native(XSLT) is export {*}

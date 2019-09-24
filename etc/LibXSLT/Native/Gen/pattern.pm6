use v6;
#  -- DO NOT EDIT --
# generated by: ../LibXML-p6/etc/generator.p6 --mod=LibXSLT --lib=XSLT etc/libxslt-api.xml

unit module LibXSLT::Native::Gen::pattern;
# interface for the pattern matching used in template matches.:
#    the implementation of the lookup of the right template for a given node must be really fast in order to keep decent performances. 
use LibXML::Native::Defs :xmlCharP;
use LibXSLT::Native::Defs :$lib;

class xsltCompMatch is repr('CPointer') {
    sub xsltCompilePattern(xmlCharP $pattern, xmlDoc $doc, xmlNode $node, xsltStylesheet $style, xsltTransformContext $runtime --> xsltCompMatch) is native(XSLT) is export {*};

    method FreeCompMatchList() is native(XSLT) is symbol('xsltFreeCompMatchList') {*};
}

sub xsltNormalizeCompSteps(Pointer $payload, Pointer $data, xmlCharP $name) is native(XSLT) is export {*};

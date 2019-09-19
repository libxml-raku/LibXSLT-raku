unit module LibXSLT::Native;

use LibXML::Native;
use LibXML::Native::Dict;
use LibXML::Native::HashTable;
use LibXML::Native::Defs :Opaque, :XML2, :xmlCharP;

use LibXSLT::Native::Defs :XSLT, :BIND-XSLT;
use NativeCall;

class xsltCompilerCtxt is repr(Opaque) {}
class xsltDecimalFormat is repr(Opaque) {}
class xsltElemPreComp is repr(Opaque) {}
class xsltPrincipalStylesheetData is repr(Opaque) {}
class xsltStylePreComp is repr(Opaque) {}
class xsltTemplate is repr(Opaque) {}

class xsltTransformContext is repr(Opaque) is export {

    method SetGenericErrorFunc(&func (xsltTransformContext $ctx, Str:D $msg, Pointer, Pointer, Pointer) ) is native(XSLT) is symbol('xsltSetGenericErrorFunc') is export {*};
    method SetStructuredErrorFunc( &error-func (xsltTransformContext $, xmlError $)) is native(XML2) is symbol('xmlSetStructuredErrorFunc') {*};
    method set-xinclude(int32) is symbol('xslt6_transform_ctx_set_xinclude') is native(BIND-XSLT) {*}

    method Free is symbol('xsltFreeTransformContext') is native(XSLT) {*}
}

class xsltDocument is repr(Opaque) is export {
}

class xsltStackElem is repr(Opaque) {
}

class xsltStylesheet is repr(Opaque) is export {
    sub xsltParseStylesheetDoc(xmlDoc $doc --> xsltStylesheet) is native(XSLT) is export {*};
    sub xsltParseStylesheetFile(xmlCharP $filename --> xsltStylesheet) is native(XSLT) is export {*};
    method NewTransformContext(xmlDoc $doc --> xsltTransformContext) is native(XSLT) is symbol('xsltNewTransformContext') {*};
    constant FILE = Pointer;
    method transform(xmlDoc $doc, xsltTransformContext $userCtxt, CArray[Str] $params --> xmlDoc) is native(BIND-XSLT) is symbol('xslt6_stylesheet_transform') {*}
    method Free is symbol('xsltFreeStylesheet') is native(XSLT) {*}
    method media-type(--> Str) is symbol('xslt6_stylesheet_media_type') is native(BIND-XSLT) {*}
    method output-method(--> Str) is symbol('xslt6_stylesheet_output_method') is native(BIND-XSLT) {*}
}

sub xsltSaveResultToString(Pointer[uint8] $out is rw, int32 $len is rw, xmlDoc $result, xsltStylesheet $style --> int32) is native(XSLT) is export {*};
sub xsltInit() is native(XSLT) is export {*};
sub xsltSetXIncludeDefault(int32 $) is native(XSLT) is export {*};

INIT {
    xsltInit();
    xsltSetXIncludeDefault(1);
}

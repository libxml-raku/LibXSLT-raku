unit module LibXSLT::Native;

use LibXML::Native;
use LibXML::Native::Dict;
use LibXML::Native::HashTable;
use LibXML::Native::Defs :Opaque, :XML2, :xmlCharP;

use LibXSLT::Native::Defs :XSLT, :EXSLT, :BIND-XSLT;
use NativeCall;

class xsltDecimalFormat is repr(Opaque) {}
class xsltCompilerCtxt is repr(Opaque) {}
class xsltPrincipalStylesheetData is repr(Opaque) {}
class xsltStylePreComp is repr(Opaque) {}
class xsltTemplate is repr(Opaque) {}

class xsltElemPreComp is repr(Opaque) is export {
    has xsltElemPreComp $.next; # next item in the global chained list held by xsltStylesheet.
    my constant xsltStyleType = int32;
    has xsltStyleType $.type; # type of the element
    constant xsltTransformFunction = Pointer;
    has xsltTransformFunction $.func; # handling function
    has anyNode $.inst; # the node in the stylesheet's tree corresponding to this item end of common part
    constant xsltElemPreCompDeallocator = Pointer;
    has xsltElemPreCompDeallocator $.free; # the deallocator
}

class xsltTransformContext is repr(Opaque) is export {

    method SetGenericErrorFunc(&func (xsltTransformContext $ctx, Str:D $msg, Pointer, Pointer, Pointer) ) is native(XSLT) is symbol('xsltSetGenericErrorFunc') is export {*};
    method SetStructuredErrorFunc( &error-func (xsltTransformContext $, xmlError $)) is native(XML2) is symbol('xmlSetStructuredErrorFunc') {*};
    method RegisterExtElement(xmlCharP $name, xmlCharP $URI, &func (
                                  xsltTransformContext,
	                          anyNode $this-node,
				  anyNode $style-node,
			          xsltElemPreComp $com) --> int32)
        is symbol('xsltRegisterExtElement')
        is native(XSLT) {*};
    method set-xinclude(int32) is symbol('xslt6_transform_ctx_set_xinclude') is native(BIND-XSLT) {*}
    method get-insert-node(--> anyNode) is symbol('xslt6_transform_ctx_get_insert_node') is native(BIND-XSLT) {*}

    method Free is symbol('xsltFreeTransformContext') is native(XSLT) {*}
}

class xsltSecurityPrefs is repr(Opaque) is export {
    sub xsltGetDefaultSecurityPrefs( --> xsltSecurityPrefs) is native(XSLT) is export {*};
    sub xsltNewSecurityPrefs( --> xsltSecurityPrefs) is native(XSLT) is export {*};
    method new() { xsltNewSecurityPrefs() }
    method CheckRead(xsltTransformContext $ctxt, xmlCharP $URL --> int32) is native(XSLT) is symbol('xsltCheckRead') {*};
    method CheckWrite(xsltTransformContext $ctxt, xmlCharP $URL --> int32) is native(XSLT) is symbol('xsltCheckWrite') {*};
    method Free() is native(XSLT) is symbol('xsltFreeSecurityPrefs') {*};
    method Get(int32 $option --> Pointer) is native(XSLT) is symbol('xsltGetSecurityPrefs') {*};
    method Allow(xsltTransformContext $ctxt, Str $value --> int32) is native(XSLT) is symbol('xsltSecurityAllow') {*};
    method Forbid(xsltTransformContext $ctxt, Str $value --> int32) is native(XSLT) is symbol('xsltSecurityForbid') {*};
    method SetContext(xsltTransformContext $ctxt --> int32) is native(XSLT) is symbol('xsltSetCtxtSecurityPrefs') {*};
    method SetDefault() is native(XSLT) is symbol('xsltSetDefaultSecurityPrefs') {*};
    method Set(int32 $option, &func (xsltSecurityPrefs, xsltTransformContext, Str --> int32) --> int32) is native(XSLT) is symbol('xsltSetSecurityPrefs') {*};
}

class xsltDocument is repr(Opaque) is export {
}

class xsltStackElem is repr(Opaque) {
}

class xsltStylesheet is repr(Opaque) is export {
    sub xsltParseStylesheetDoc(xmlDoc $doc --> xsltStylesheet) is native(XSLT) is export {*};
    sub xsltParseStylesheetFile(xmlCharP $filename --> xsltStylesheet) is native(XSLT) is export {*};
    sub xsltLoadStylesheetPI(xmlDoc $doc --> xsltStylesheet) is native(XSLT) is export {*};
    method NewTransformContext(xmlDoc $doc --> xsltTransformContext) is native(XSLT) is symbol('xsltNewTransformContext') {*};
    constant FILE = Pointer;
    method transform(xmlDoc $doc, xsltTransformContext $userCtxt, CArray[Str] $params --> xmlDoc) is native(BIND-XSLT) is symbol('xslt6_stylesheet_transform') {*}
    method Free is symbol('xsltFreeStylesheet') is native(XSLT) {*}
    method media-type(--> Str) is symbol('xslt6_stylesheet_media_type') is native(BIND-XSLT) {*}
    method output-method(--> Str) is symbol('xslt6_stylesheet_output_method') is native(BIND-XSLT) {*}
}

sub xsltSaveResultToString(Pointer[uint8] $out is rw, int32 $len is rw, xmlDoc $result, xsltStylesheet $style --> int32) is native(XSLT) is export {*};
sub xsltInit() is native(XSLT) is export {*};
sub xsltSetXIncludeDefault(int32) is native(XSLT) is export {*};
sub xsltMaxDepth is export { cglobal(XSLT, 'xsltMaxDepth', int32); }
sub xslt6_gbl_set_max_depth(int32) is native(BIND-XSLT) is export {*};
sub xsltMaxVars is export { cglobal(XSLT, 'xsltMaxVars', int32); }
sub xslt6_gbl_set_max_vars(int32) is native(BIND-XSLT) is export {*};
sub xslt6_config_have_exslt(--> int32) is native(BIND-XSLT) is export {*};
sub xslt6_config_version(--> Str) is native(BIND-XSLT) is export {*};
sub xsltLibxsltVersion is export { cglobal(XSLT, 'xsltLibxsltVersion', int32); }
sub xsltLibxxmlVersion is export { cglobal(XSLT, 'xsltLibxxmlVersion', int32); }
sub xsltRegisterExtModuleFunction(xmlCharP $name, xmlCharP $URI, &func2 (xmlXPathParserContext, int32 --> xmlXPathObject) --> int32) is native(XSLT) is export {*};
sub xsltSetGenericDebugFunc(Pointer $ctx, &func (Pointer $ctx2, Str $msg, Pointer, Pointer, Pointer)) is native(XSLT) is export {*};

sub exsltRegisterAll() is native(EXSLT) is export {*};

INIT {
    xsltInit();
    xsltSetXIncludeDefault(1);
    if xslt6_config_have_exslt() {
        exsltRegisterAll();
    }
}

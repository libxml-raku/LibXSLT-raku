unit module LibXSLT::Native;

use LibXML::Native;
use LibXML::Native::Dict;
use LibXML::Native::HashTable;
use LibXML::Native::Defs :Opaque, :xmlCharP;

use LibXSLT::Native::Defs :XSLT;
use NativeCall;

class xsltCompilerCtxt is repr(Opaque) {}
class xsltDecimalFormat is repr(Opaque) {}
class xsltElemPreComp is repr(Opaque) {}
class xsltPrincipalStylesheetData is repr(Opaque) {}
class xsltStylePreComp is repr(Opaque) {}
class xsltTemplate is repr(Opaque) {}

class xsltTransformContext is repr(Opaque) is export {

    method SetGenericErrorFunc(&func (xsltTransformContext $ctx, Str:D $msg, Pointer $arg) ) is native(XSLT) is symbol('xsltSetGenericErrorFunc') is export {*};
    method Free is symbol('xsltFreeTransformContext') is native(XSLT) {*}
}

class xsltDocument is repr('CStruct') is export {
    has xsltDocument $.next; # documents are kept in a chained list
    has int32 $.main; # is this the main document
    has xmlDoc $.doc; # the parsed document
    has Pointer $.keys; # key tables storage
    has xsltDocument $.includes; # subsidiary includes
    has int32 $.preproc; # pre-processing already done
    has int32 $.nbKeysComputed;
    method xsltFreeDocumentKeys() is native(XSLT) {*};
}

class xsltStackElem is repr('CStruct') {
    has xsltStackElem $.next; # chained list
    has xsltStylePreComp $.comp; # the compiled form
    has int32 $.computed; # was the evaluation done
    has xmlCharP $.name; # the local part of the name QName
    has xmlCharP $.nameURI; # the URI part of the name QName
    has xmlCharP $.select; # the eval string
    has xmlNode $.tree; # the sequence constructor if no eval string or the location
    has xmlXPathObject $.value; # The value if computed
    has xmlDoc $.fragment; # The Result Tree Fragments (needed for XSLT 1.0) which are bound to the variable's lifetime.
    has int32 $.level; # the depth in the tree; -1 if persistent (e.g. a given xsl:with-param)
    has xsltTransformContext $.context; # The transformation context; needed to cache the variables
    has int32 $.flags;
    method xsltFreeStackElemList() is native(XSLT) {*};
}

class xsltStylesheet is repr('CStruct') is export {
    has xsltStylesheet $.parent;
    has xsltStylesheet $.next;
    has xsltStylesheet $.imports;
    has xsltDocument $.docList; # * General data on the style sheet document. *
    has xmlDoc $.doc; # the parsed XML stylesheet
    has xmlHashTable $.stripSpaces; # the hash table of the strip-space and preserve space elements
    has int32 $.stripAll; # strip-space * (1) preserve-space * (-1)
    has xmlHashTable $.cdataSection; # * Global variable or parameters. *
    has xsltStackElem $.variables; # * Template descriptions. *
    has xsltTemplate $.templates; # the ordered list of templates
    has Pointer $.templatesHash; # hash table or wherever compiled templates information is stored
    has Pointer $.rootMatch; # template based on /
    has Pointer $.keyMatch; # template based on key()
    has Pointer $.elemMatch; # template based on *
    has Pointer $.attrMatch; # template based on @*
    has Pointer $.parentMatch; # template based on ..
    has Pointer $.textMatch; # template based on text()
    has Pointer $.piMatch; # template based on processing-instruction()
    has Pointer $.commentMatch; # * Namespace aliases. * NOTE: Not used in the refactored code. *
    has xmlHashTable $.nsAliases; # * Attribute sets. *
    has xmlHashTable $.attributeSets; # * Namespaces. * TODO: Eliminate this. *
    has xmlHashTable $.nsHash; # the set of namespaces in use: ATTENTION: This is used for execution of XPath expressions; unfortunately it restricts the stylesheet to have distinct prefixes. TODO: We need to get rid of this. *
    has Pointer $.nsDefs; # * Key definitions. *
    has Pointer $.keys; # * Output related stuff. *
    has xmlCharP $.method; # the output method
    has xmlCharP $.methodURI; # associated namespace if any
    has xmlCharP $.version; # version string
    has xmlCharP $.encoding; # encoding string
    has int32 $.omitXmlDeclaration; # * Number formatting. *
    has xsltDecimalFormat $.decimalFormat;
    has int32 $.standalone; # standalone = "yes" | "no"
    has xmlCharP $.doctypePublic; # doctype-public string
    has xmlCharP $.doctypeSystem; # doctype-system string
    has int32 $.indent; # should output being indented
    has xmlCharP $.mediaType; # * Precomputed blocks. *
    has xsltElemPreComp $.preComps; # list of precomputed blocks
    has int32 $.warnings; # number of warnings found at compilation
    has int32 $.errors; # number of errors found at compilation
    has xmlCharP $.exclPrefix; # last excluded prefixes
    has Pointer[xmlCharP] $.exclPrefixTab; # array of excluded prefixes
    has int32 $.exclPrefixNr; # number of excluded prefixes in scope
    has int32 $.exclPrefixMax; # size of the array
    has Pointer $._private; # * Extensions. *
    has xmlHashTable $.extInfos; # the extension data
    has int32 $.extrasNr; # * For keeping track of nested includes *
    has xsltDocument $.includes; # * dictionary: shared between stylesheet, context and documents. *
    has xmlDict $.dict; # * precompiled attribute value templates. *
    has Pointer $.attVTs; # * if namespace-alias has an alias for the default stylesheet prefix * NOTE: Not used in the refactored code. *
    has xmlCharP $.defaultAlias; # * bypass pre-processing (already done) (used in imports) *
    has int32 $.nopreproc; # * all document text strings were internalized *
    has int32 $.internalized; # * Literal Result Element as Stylesheet c.f. section 2.3 *
    has int32 $.literal_result; # * The principal stylesheet *
    has xsltStylesheet $.principal; # * Compilation context used during compile-time. *
    has xsltCompilerCtxt $.compCtxt; # TODO: Change this to (void *).
    has xsltPrincipalStylesheetData $.principalData; # * Forwards-compatible processing *
    has int32 $.forwards_compatible;
    has xmlHashTable $.namedTemplates; # hash table of named templates
    has xmlXPathContext $.xpathCtxt;

    sub xsltParseStylesheetDoc(xmlDoc $doc --> xsltStylesheet) is native(XSLT) is export {*};
    sub xsltParseStylesheetFile(xmlCharP $filename --> xsltStylesheet) is native(XSLT) is export {*};
    method NewTransformContext(xmlDoc $doc --> xsltTransformContext) is native(XSLT) is symbol('xsltNewTransformContext') {*};
    constant FILE = Pointer;
    method ApplyUser(xmlDoc $doc, CArray[Str] $params, Str $output, Pointer $profile, xsltTransformContext $userCtxt --> xmlDoc) is native(XSLT) is symbol('xsltApplyStylesheetUser') {*};
    method Free is symbol('xsltFreeStylesheet') is native(XSLT) {*}
}

sub xsltSaveResultToString(Pointer[uint8] $out is rw, int32 $len is rw, xmlDoc $result, xsltStylesheet $style --> int32) is native(XSLT) is export {*};

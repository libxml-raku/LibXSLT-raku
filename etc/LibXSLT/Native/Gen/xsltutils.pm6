use v6;
#  -- DO NOT EDIT --
# generated by: ../LibXML-p6/etc/generator.p6 --mod=LibXSLT --lib=XSLT etc/libxslt-api.xml

unit module LibXSLT::Native::Gen::xsltutils;
# set of utilities for the XSLT engine:
#    interfaces for the utilities module of the XSLT engine. things like message handling, profiling, and other generally useful routines. 
use LibXML::Native::Defs :xmlCharP;
use LibXSLT::Native::Defs :$lib;

enum xsltDebugStatusCodes is export (
    XSLT_DEBUG_CONT => 6,
    XSLT_DEBUG_INIT => 1,
    XSLT_DEBUG_NEXT => 4,
    XSLT_DEBUG_NONE => 0,
    XSLT_DEBUG_QUIT => 9,
    XSLT_DEBUG_RUN => 7,
    XSLT_DEBUG_RUN_RESTART => 8,
    XSLT_DEBUG_STEP => 2,
    XSLT_DEBUG_STEPOUT => 3,
    XSLT_DEBUG_STOP => 5,
);

enum xsltDebugTraceCodes is export (
    XSLT_TRACE_ALL => -1,
    XSLT_TRACE_APPLY_TEMPLATE => 4,
    XSLT_TRACE_APPLY_TEMPLATES => 512,
    XSLT_TRACE_CALL_TEMPLATE => 256,
    XSLT_TRACE_CHOOSE => 1024,
    XSLT_TRACE_COMMENT => 16,
    XSLT_TRACE_COPY => 8,
    XSLT_TRACE_COPY_OF => 64,
    XSLT_TRACE_COPY_TEXT => 1,
    XSLT_TRACE_FOR_EACH => 4096,
    XSLT_TRACE_IF => 2048,
    XSLT_TRACE_KEYS => 32768,
    XSLT_TRACE_NONE => 0,
    XSLT_TRACE_PI => 32,
    XSLT_TRACE_PROCESS_NODE => 2,
    XSLT_TRACE_STRIP_SPACES => 8192,
    XSLT_TRACE_TEMPLATES => 16384,
    XSLT_TRACE_VALUE_OF => 128,
    XSLT_TRACE_VARIABLES => 65536,
);

sub xslDropCall() is native(XSLT) is export {*};
sub xsltCalibrateAdjust(long $delta) is native(XSLT) is export {*};
sub xsltDebugGetDefaultTrace( --> xsltDebugTraceCodes) is native(XSLT) is export {*};
sub xsltDebugSetDefaultTrace(xsltDebugTraceCodes $val) is native(XSLT) is export {*};
sub xsltDocumentSortFunction(xmlNodeSet $list) is native(XSLT) is export {*};
sub xsltGetDebuggerStatus( --> int32) is native(XSLT) is export {*};
sub xsltGetNsProp(xmlNode $node, xmlCharP $name, xmlCharP $nameSpace --> xmlCharP) is native(XSLT) is export {*};
sub xsltGetQNameURI(xmlNode $node, xmlChar ** $name --> xmlCharP) is native(XSLT) is export {*};
sub xsltGetUTF8Char(const unsigned char * $utf, Pointer[int32] $len --> int32) is native(XSLT) is export {*};
sub xsltSaveResultTo(xmlOutputBuffer $buf, xmlDoc $result, xsltStylesheet $style --> int32) is native(XSLT) is export {*};
sub xsltSaveResultToFd(int32 $fd, xmlDoc $result, xsltStylesheet $style --> int32) is native(XSLT) is export {*};
sub xsltSaveResultToFile(FILE * $file, xmlDoc $result, xsltStylesheet $style --> int32) is native(XSLT) is export {*};
sub xsltSaveResultToFilename(Str $URL, xmlDoc $result, xsltStylesheet $style, int32 $compression --> int32) is native(XSLT) is export {*};
sub xsltSaveResultToString(xmlChar ** $doc_txt_ptr, Pointer[int32] $doc_txt_len, xmlDoc $result, xsltStylesheet $style --> int32) is native(XSLT) is export {*};
sub xsltSetDebuggerCallbacks(int32 $no, Pointer $block --> int32) is native(XSLT) is export {*};
sub xsltSetDebuggerStatus(int32 $value) is native(XSLT) is export {*};
sub xsltSetGenericDebugFunc(Pointer $ctx, xmlGenericErrorFunc $handler) is native(XSLT) is export {*};
sub xsltSetGenericErrorFunc(Pointer $ctx, xmlGenericErrorFunc $handler) is native(XSLT) is export {*};
sub xsltSetSortFunc(xsltSortFunc $handler) is native(XSLT) is export {*};
sub xsltSplitQName(xmlDict $dict, xmlCharP $name, const xmlChar ** $prefix --> xmlCharP) is native(XSLT) is export {*};
sub xsltTimestamp( --> long) is native(XSLT) is export {*};

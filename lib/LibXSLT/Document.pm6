use v6;
use LibXML::Document;

unit class LibXSLT::Document
    is LibXML::Document;

use LibXML::Native::Defs :CLIB;
use NativeCall;
use LibXSLT::Native;
use LibXSLT::Stylesheet;
has LibXSLT::Stylesheet $.xslt is required;


method Blob {
    my Pointer[uint8] $ptr .= new;
    my int32 $len;
    my buf8 $buf;
    sub memcpy(Blob, Pointer, size_t) is native(CLIB) {*}
    sub free(Pointer) is native(CLIB) {*}

    with self {
        xsltSaveResultToString($ptr, $len, self.native, $!xslt.native);
        $buf .= allocate($len);
        memcpy($buf, $ptr, $len);
        free($ptr);
    }
    $buf;
}

method Str {
    self.Blob.decode;
}

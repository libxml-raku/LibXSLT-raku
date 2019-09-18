use v6;
use LibXML::Document;

unit class LibXSLT::Document
    is LibXML::Document;

use LibXML;
use LibXML::Native::Defs :CLIB;
use LibXSLT::Native;
use LibXSLT::Stylesheet;
has LibXSLT::Stylesheet $.xslt is required;
use NativeCall;

method Blob-xslt {
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

multi method Blob(:$xslt! where .so) { $.Blob-xslt }
multi method Blob is default { callsame() }

method Str-xslt { self.Blob-xslt.decode; }
multi method Str(:$xslt! where .so) { $.Str-xslt }
multi method Str is default { callsame(); }

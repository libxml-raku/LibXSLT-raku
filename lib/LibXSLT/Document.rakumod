use v6;
use LibXML::Document;

unit class LibXSLT::Document
    is LibXML::Document;

use LibXML;
use LibXML::Raw;
use LibXML::Raw::Defs :$CLIB;
use LibXSLT::Raw;
use LibXSLT::Stylesheet;
has LibXSLT::Stylesheet $.stylesheet is required;
use NativeCall;

our role Xslt {
    method Blob {
        my Pointer[uint8] $ptr .= new;
        my int32 $len;
        my buf8 $buf;
        sub memcpy(Blob, Pointer, size_t) is native($CLIB) {*}
        sub free(Pointer) is native($CLIB) {*}

        with self {
            xsltSaveResultToString($ptr, $len, $.raw, $.stylesheet.raw);
            $buf .= allocate($len);
            memcpy($buf, $ptr, $len);
            free($ptr);
        }
        $buf;
    }

    method Str { self.Blob.decode; }
    method serialize { $.Str }
}

method Xslt {
    self ~~ Xslt
        ?? self
        !! (self does Xslt);
}

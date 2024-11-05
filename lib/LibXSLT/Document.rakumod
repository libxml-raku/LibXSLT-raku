unit class LibXSLT::Document;

use LibXML::Document;
also is LibXML::Document;

use LibXML;
use LibXML::Raw;
use LibXSLT::Raw;
use LibXSLT::Stylesheet;
has LibXSLT::Stylesheet $.stylesheet is required;
use NativeCall;

our role Xslt {
    method Blob {
        my Pointer[uint8] $ptr .= new;
        my int32 $len;
        my buf8 $buf;

        with self {
            xsltSaveResultToString($ptr, $len, $.raw, $.stylesheet.raw);
            $buf .= allocate($len);
            LibXML::Raw::CLib::memcpy($buf, $ptr, $len);
            LibXML::Raw::CLib::free($ptr);
        }
        $buf;
    }

    method Str { self.Blob.decode; }
    method serialize { $.Str }
    multi method COERCE(LibXSLT::Document:D $_) { .Xslt() }
}

multi method Xslt(Xslt:) { self }
multi method Xslt { self does Xslt }


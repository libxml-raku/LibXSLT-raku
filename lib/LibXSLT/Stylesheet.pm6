unit class LibXSLT::Stylesheet;

use LibXSLT::Native;
use LibXSLT::TransformContext;

use LibXML::Config;
use LibXML::Document;
use LibXML::Native;
use LibXML::Native::Defs :CLIB;
use LibXML::ErrorHandler :&structured-error-cb, :&generic-error-cb;
use LibXSLT::Security;
use NativeCall;

has LibXSLT::Security $.security is rw;

constant config = LibXML::Config;

has $.input-callbacks is rw = config.input-callbacks;
multi method input-callbacks is rw { $!input-callbacks }
multi method input-callbacks($!input-callbacks) {}

has xsltStylesheet $!native handles <media-type output-method>;
has Hash %!extensions;
method native { $!native }

method register-transform('element', $URI, $name, &element) {
    %!extensions{$URI//''}{$name} = :&element;
}

submethod DESTROY {
    .Free with $!native;
}

method !try(&action) {
    my $*XML-CONTEXT = LibXML::ErrorHandler.new;
    my $*XSLT-SECURITY = $!security;

    xsltTransformContext.SetGenericErrorFunc: &generic-error-cb;
    xsltTransformContext.SetStructuredErrorFunc: &structured-error-cb;
    .set-default()
        with $!security;

    my @input-contexts = .activate()
        with $.input-callbacks;

    &*chdir(~$*CWD);
    my $rv := &action();

    .deactivate with $.input-callbacks;
    .flush-errors for @input-contexts;
    $*XML-CONTEXT.flush-errors;

    $rv;
}

proto method parse-stylesheet(|c) {
    with self {return {*}} else { self.new.parse-stylesheet(|c) }
}

multi method parse-stylesheet(LibXML::Document:D :$doc! --> LibXSLT::Stylesheet) {
    self!try: {
        my $doc-copy = $doc.native.copy: :deep;
        with xsltParseStylesheetDoc($doc-copy) {
            .Free with $!native;
            $!native = $_;
        }
    }
    self;
}

multi method parse-stylesheet(Str:D() :$file! --> LibXSLT::Stylesheet) {
    self!try: {
        with xsltParseStylesheetFile($file) {
            .Free with $!native;
            $!native = $_;
        }
    }
    self;
}

multi method parse-stylesheet(LibXML::Document:D $doc) {
    self.parse-stylesheet: :$doc;
}

multi method transform(LibXML::Document:D :$doc!, *%params --> LibXML::Document) {
    my LibXSLT::TransformContext $ctx .= new: :$doc, :stylesheet(self), :$!input-callbacks, :%!extensions, :$!security;
    my CArray[Str] $params .= new(|%params.kv, Str);
    my xmlDoc $result;
    $ctx.try: {
        $result = $!native.transform($doc.native, $ctx.native, $params);
    }
    (require LibXSLT::Document).new: :native($result), :stylesheet(self);
}

multi method transform(:$file!, |c --> LibXML::Document) {
    my LibXML::Document:D $doc .= parse: :$file;
    self.transform: :$doc, |c;
}

multi method transform(LibXML::Document:D $doc, |c) {
    self.transform: :$doc, |c;
}

method process(LibXML::Document:D :$xml!, LibXML::Document:D :$xsl!, |c --> Str) {
    my LibXSLT::Stylesheet $stylesheet = $.parse-stylesheet($xsl);
    my LibXML::Document $results = $stylesheet.transform($xml, |c).Xslt;
    $results.Str;
}

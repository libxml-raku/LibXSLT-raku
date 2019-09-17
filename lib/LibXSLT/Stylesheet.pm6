unit class LibXSLT::Stylesheet;

use LibXSLT::Native;
use LibXSLT::TransformContext;

use LibXML::Document;
use LibXML::Native;
use LibXML::Native::Defs :CLIB;

use NativeCall;

has xsltStylesheet $!native;
method native { $!native }

submethod DESTROY {
    .Free with $!native;
}

proto method parse-stylesheet(|c) {
    with self {return {*}} else { self.new.parse-stylesheet(|c) }
}

multi method parse-stylesheet(LibXML::Document:D :$doc! is copy --> LibXSLT::Stylesheet) {
    .Free with $!native;
    $!native = xsltParseStylesheetDoc($doc.native.copy: :deep);
    self;
}

multi method parse-stylesheet(Str:D() :$file! is copy --> LibXSLT::Stylesheet) {
    .Free with $!native;
    $!native = xsltParseStylesheetFile($file);
    self;
}

multi method transform(LibXML::Document:D :$doc! --> LibXML::Document) {
    my LibXSLT::TransformContext $ctx .= new: :$doc, :stylesheet(self);
    my xmlDoc $out-doc = $!native.ApplyUser($doc.native, Pointer, Str, Pointer, $ctx.native);
    (require LibXSLT::Document).new: :native($out-doc), :xslt(self);
}


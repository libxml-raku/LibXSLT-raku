unit class LibXSLT::Stylesheet;

use LibXSLT::Native;
use LibXSLT::TransformContext;
use LibXML::Document;
use LibXML::Native;
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
    $doc .= box($doc.native.copy);
    .Free with $!native;
    $!native = xsltParseStylesheetDoc($doc.native);
    self;
}

multi method parse-stylesheet(Str:D() :$file! is copy --> LibXSLT::Stylesheet) {
    .Free with $!native;
    $!native = xsltParseStylesheetFile($file);
    self;
}

multi method transform(LibXML::Document:D :$doc! --> LibXML::Document) {
    my LibXSLT::TransformContext $ctx .= new: :$doc, :stylesheet(self);
    warn ($doc.native.WHAT, Pointer, Str, Pointer, $ctx.native.WHAT).perl;
    my xmlDoc $out-doc = $!native.ApplyUser($doc.native, Pointer, Str, Pointer, $ctx.native);
    LibXML::Document.box: $out-doc;
}


unit class LibXSLT::TransformContext;

use LibXML::Document;
use LibXSLT::Native;

has xsltTransformContext $!native;
method native { $!native }

multi submethod TWEAK(:$stylesheet!, LibXML::Document:D :$doc!) {
    $!native = $stylesheet.native.NewTransformContext($doc.native);
}

submethod DESTROY {
    .Free with $!native;
}

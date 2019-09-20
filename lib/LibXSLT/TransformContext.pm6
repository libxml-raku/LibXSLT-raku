unit class LibXSLT::TransformContext;

use LibXML::Document;
use LibXML::Native;
use LibXSLT::Native;
use NativeCall;
use LibXML::ErrorHandler :&structured-error-cb, :&generic-error-cb;
use LibXML::XPath::Context;

has xsltTransformContext $!native;
method native { $!native }
has $.input-callbacks;
has LibXML::XPath::Context $!ctx handles<structured-error generic-error flush-errors park> .= new;

multi submethod TWEAK(:$stylesheet!, LibXML::Document:D :$doc!) {
    $!native = $stylesheet.native.NewTransformContext($doc.native);
    $!native.set-xinclude(1);
}

submethod DESTROY {
    .Free with $!native;
}

sub park($v) {
    warn "parking stub...";
    $v;
}

method try(&action) {
    my $*XML-CONTEXT = self;
    $_ .= new without $*XML-CONTEXT;
    $*XML-CONTEXT.native.SetGenericErrorFunc: &generic-error-cb;
    $*XML-CONTEXT.native.SetStructuredErrorFunc: &structured-error-cb;

    my @input-contexts = .activate()
        with $*XML-CONTEXT.input-callbacks;

    &*chdir(~$*CWD);
    my $rv := action();

    .deactivate 
        with $*XML-CONTEXT.input-callbacks;

    .flush-errors for @input-contexts;
    $*XML-CONTEXT.flush-errors;

    $rv
}

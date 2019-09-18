unit class LibXSLT::TransformContext;

use LibXML::Document;
use LibXML::Native;
use LibXSLT::Native;
use NativeCall;

has xsltTransformContext $!native;
method native { $!native }
has $.input-callbacks;
has LibXML::ErrorHandler $!errors handles<generic-error flush-errors> .= new;

sub generic-error-cb($ctx, Str $fmt, |args) {
    CATCH { default { warn "error handling XSLT error: $_" } }
    $*XSLT-CONTEXT.generic-error($fmt, |args);
}

multi submethod TWEAK(:$stylesheet!, LibXML::Document:D :$doc!) {
    $!native = $stylesheet.native.NewTransformContext($doc.native);
    $!native.SetGenericErrorFunc: &generic-error-cb;
    $!native.set-xinclude(1);
}

submethod DESTROY {
    .Free with $!native;
}

method try(&action) {
    my $*XSLT-CONTEXT = self;
    $_ .= new without $*XSLT-CONTEXT;

    my @input-contexts = .activate()
        with $*XSLT-CONTEXT.input-callbacks;

    &*chdir(~$*CWD);
    my $rv := action();

    .deactivate 
        with $*XSLT-CONTEXT.input-callbacks;

    .flush-errors for @input-contexts;
    $*XSLT-CONTEXT.flush-errors;

    $rv
}

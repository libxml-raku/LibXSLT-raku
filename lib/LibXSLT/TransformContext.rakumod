unit class LibXSLT::TransformContext;

use LibXSLT::Raw;
use LibXSLT::Raw::Defs :$XSLT;
use LibXSLT::Security;
use LibXSLT::ExtensionContext;

use LibXML::Document;
use LibXML::ErrorHandling :&structured-error-cb, :&generic-error-cb;
use LibXML::Raw;
use LibXML::XPath::Context;

use NativeCall;

has xsltTransformContext $!raw;
method raw { $!raw }
has $.input-callbacks;
has Hash %!extensions;
has LibXSLT::Security $.security;
has $.stylesheet is required handles <structured-error generic-error callback-error flush-errors park suppress-warnings suppress-errors>;

multi submethod TWEAK(LibXML::Document :$doc, :%extensions, |c) {
    my xmlDoc $doc-raw = .raw with $doc;
    $!raw = $!stylesheet.raw.NewTransformContext($doc-raw);
    $!raw.set-xinclude(1);
    for %extensions {
        my $uri = .key;
        for .value.kv -> $name, Pair $_ {
            my Str $type = .key;
            my &func = .value;
            self.register-transform($type, $uri, $name, &func);
        }
    }
}

submethod DESTROY {
    .Free with $!raw;
}

method register-transform($type, Str $URI, Str:D $name, &func) {
    %!extensions{$URI||''}{$name} = $type => &func;
    $!raw.RegisterExtElement($name, $URI, -> xsltTransformContext $ctx, anyNode $source-raw, anyNode $style-raw, xsltElemPreComp $comp {
        CATCH { default { $*XML-CONTEXT.callback-error: X::LibXML::XPath::AdHoc.new: :error($_); } }
        my $insert-raw = .get-insert-node with $ctx;
        my LibXSLT::ExtensionContext $ext-ctx .= new: :$source-raw, :$style-raw, :$insert-raw, :$comp;
        &func($ext-ctx);
    });
}

method SetGenericErrorFunc(&handler) {
    xml6_gbl::set-generic-error-handler(
        -> Str $msg {
            CATCH { default { note $_; $*XML-CONTEXT.callback-error: X::LibXML::XPath::AdHoc.new: :error($_) } }
            &handler($msg);
        },
        cglobal($XSLT, 'xsltSetGenericErrorFunc', Pointer)
    );
}

method try(&action) is hidden-from-backtrace {
    my $*XML-CONTEXT = self;
    $_ .= new without $*XML-CONTEXT;

    my $*XSLT-SECURITY = $*XML-CONTEXT.security;
    with $*XSLT-SECURITY {
        .set-context($*XML-CONTEXT);
    }
    else {
        .set-default();
    }

    $*XML-CONTEXT.SetGenericErrorFunc: &generic-error-cb;
    $*XML-CONTEXT.raw.SetStructuredErrorFunc: &structured-error-cb;

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

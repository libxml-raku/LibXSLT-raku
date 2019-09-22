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
has Hash %!extensions;
has LibXML::XPath::Context $!ctx handles<structured-error generic-error callback-error flush-errors park> .= new;

multi submethod TWEAK(:$stylesheet!, LibXML::Document:D :$doc!, :%extensions) {
    $!native = $stylesheet.native.NewTransformContext($doc.native);
    $!native.set-xinclude(1);
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
    .Free with $!native;
}

class ExtensionContext {
    has xsltElemPreComp $!comp;

    has anyNode  $!this-native;
    has LibXML::Node $!this;
    method this-node { $!this //= LibXML::Node.box($!this-native); }

    has anyNode  $!style-native;
    has LibXML::Node $!style;
    method style-node { $!style //= LibXML::Node.box($!style-native); }

    has anyNode  $!insert-native;
    has LibXML::Node $!insert;
    method insert-node { $!insert //= LibXML::Node.box($!insert-native); }

    submethod TWEAK(anyNode :$!this-native!, anyNode :$!insert-native!, xsltElemPreComp:D :$!comp!, :$!style-native) {
        $!style-native //= $!comp.inst;
    }
}

method register-transform($type, Str $URI, Str:D $name, &func) {
    %!extensions{$URI||''}{$name} = $type => &func;
    $!native.RegisterExtElement($name, $URI, -> xsltTransformContext $ctx, anyNode $this-native, anyNode $style-native, xsltElemPreComp $comp {
        CATCH { default { warn $_; $*XML-CONTEXT.callback-error: X::LibXML::XPath::AdHoc.new: :error($_) } }
        my $insert-native = .get-insert-node with $ctx;
        my ExtensionContext $ext-ctx .= new: :$this-native, :$style-native, :$insert-native, :$comp;
        &func($ext-ctx);
    });
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

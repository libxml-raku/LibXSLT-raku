unit class LibXSLT::TransformContext;

use LibXSLT::Native;
use LibXSLT::Native::Defs :XSLT;
use LibXSLT::Security;
use LibXSLT::ExtensionContext;

use LibXML::Document;
use LibXML::ErrorHandler :&structured-error-cb, :&generic-error-cb, :MsgArg;
use LibXML::Native;
use LibXML::XPath::Context;

use NativeCall;

has xsltTransformContext $!native;
method native { $!native }
has $.input-callbacks;
has Hash %!extensions;
has LibXSLT::Security $.security;
has $.stylesheet is required handles <structured-error generic-error callback-error flush-errors park suppress-warnings suppress-errors>;

multi submethod TWEAK(LibXML::Document :$doc, :%extensions, |c) {
    my xmlDoc $doc-native = .native with $doc;
    $!native = $!stylesheet.native.NewTransformContext($doc-native);
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


method register-transform($type, Str $URI, Str:D $name, &func) {
    %!extensions{$URI||''}{$name} = $type => &func;
    $!native.RegisterExtElement($name, $URI, -> xsltTransformContext $ctx, anyNode $source-native, anyNode $style-native, xsltElemPreComp $comp {
        CATCH { default { warn $_; $*XML-CONTEXT.callback-error: X::LibXML::XPath::AdHoc.new: :error($_) } }
        my $insert-native = .get-insert-node with $ctx;
        my LibXSLT::ExtensionContext $ext-ctx .= new: :$source-native, :$style-native, :$insert-native, :$comp;
        &func($ext-ctx);
    });
}

sub _set-generic-error-handler( &func (Str $fmt, Str $argt, Pointer[MsgArg] $argv), Pointer ) is native(XSLT) is symbol('xsltSetGenericErrorFunc') is export {*}

method SetGenericErrorFunc(&handler) {
    _set-generic-error-handler(
        -> Str $msg, Str $fmt, Pointer[MsgArg] $argv {
            CATCH { default { warn $_; $*XML-CONTEXT.callback-error: X::LibXML::XPath::AdHoc.new: :error($_) } }
            my @args = LibXML::ErrorHandler::cast-var-args($fmt, $argv);
            &handler($msg, @args);
        },
        xml6_gbl_message_func
    );
}

method try(&action) {
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

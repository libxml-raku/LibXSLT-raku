unit class LibXSLT::Stylesheet;

use LibXSLT::Native;
use LibXSLT::TransformContext;

use LibXML::Config;
use LibXML::Document :HTML;
use LibXML::PI;
use LibXML::Native;
use LibXML::Native::Defs :CLIB;
use LibXML::XPath::Context;
use LibXML::ErrorHandling :&structured-error-cb, :&generic-error-cb;
use LibXSLT::Security;
use URI;
use NativeCall;

constant config = LibXML::Config;

has LibXML::XPath::Context $!ctx handles<structured-error generic-error callback-error flush-errors park suppress-warnings suppress-errors>;
has LibXSLT::Security $.security is rw;
has $.input-callbacks is rw = config.input-callbacks;
has xsltStylesheet $!native handles<output-method>;
has Hash %!extensions;

method TWEAK(|c) {
    $!ctx .= new: |c;
}

submethod DESTROY {
    .Free with $!native;
}

multi method input-callbacks is rw { $!input-callbacks }
multi method input-callbacks($!input-callbacks) {}

method native { $!native }

method register-transform('element', $URI, $name, &element) {
    %!extensions{$URI//''}{$name} = :&element;
}

method !try(&action) {
    my $*XML-CONTEXT = self;
    $_ .= new() without $*XML-CONTEXT;
    my $*XSLT-SECURITY = $*XML-CONTEXT.security;

    LibXSLT::TransformContext.SetGenericErrorFunc: &generic-error-cb;
    xsltTransformContext.SetStructuredErrorFunc: &structured-error-cb;
    $*XSLT-SECURITY.set-default();

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

method media-type {
    # this below is rather simplistic, but should work for most cases
    $!native.media-type // do with $.output-method {
        when 'xml'|'html' { 'text/' ~ $_ }
        default { 'text/plain' }
    } // Str;
}

multi method parse-stylesheet(LibXML::Document:D :$doc! --> LibXSLT::Stylesheet) {
    self!try: {
        my $doc-copy = $doc.native.copy: :deep;
        with xsltStylesheet::ParseDoc($doc-copy) {
            .Free with $!native;
            $!native = $_;
        }
    }
    self;
}

multi method parse-stylesheet(Str:D() :$file! --> LibXSLT::Stylesheet) {
    self!try: {
        with xsltStylesheet::ParseFile($file) {
            .Free with $!native;
            $!native = $_;
        }
    }
    self;
}

multi method parse-stylesheet(LibXML::Document:D $doc) {
    self.parse-stylesheet: :$doc;
}

our sub xpath-to-string(*%xpath) is export(:xpath-to-string) {
    %xpath.map: {
        my $key = .key.subst(':', '_', :g);
        my $arg = do given .value {
            when Str {
                my $value = $_ // '';
                $value ~~ s:g/\'/', "'", '/
                    ?? "concat('$value')"
                    !! "'{$value}'";
            }
            when .isa(Bool) { $_ ?? 'true()' !! 'false()' }
            when Numeric { .Str }
            default {
                warn "ignoring XPath value: {.perl}" if .defined;
                "''"
            }
       }
          
       $key => $arg;
    }
}

multi method transform(LibXML::Document:D :$doc!, Bool :$raw, *%params --> LibXML::Document) {
    my LibXSLT::TransformContext $ctx .= new: :$doc, :stylesheet(self), :$!input-callbacks, :%!extensions, :$!security;
    %params = xpath-to-string(|%params) unless $raw;
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

proto method load-stylesheet-pi(|c) {
    with self {return {*}} else { self.new.load-stylesheet-pi(|c) }
}

multi method load-stylesheet-pi(LibXML::Document:D :$doc!) {
    self!try({
        do with xsltStylesheet::LoadPI($doc.native) {
            .Free with $!native;
            $!native = $_;
        }
    }) // fail "unable to load a stylesheet for this document";
    self
}

method process(LibXML::Document:D :$doc!, LibXML::Document :$xsl, |c --> Str) {
    my LibXSLT::Stylesheet $stylesheet = do with $xsl {
        $.parse-stylesheet($xsl);
    }
    else {
        self.load-stylesheet-pi(:$doc);
    }
    my LibXML::Document $results = $stylesheet.transform(:$doc, |c).Xslt;
    $results.Str;
}

=begin pod

=head1 NAME

LibXSLT::Stylesheet

=head1 DESCRIPTION

The main API is on the stylesheet, though it is fairly minimal.

One of the main advantages of LibXSLT is that you have a generic
stylesheet object which you call the C<transform()> method passing in a
document to transform. This allows you to have multiple transformations
happen with one stylesheet without requiring a reparse.

=begin item
transform(:$doc, %params)

  my $results = $stylesheet.transform(:$doc, foo => "'bar'");
  print $results.Xslt.Str;

Transforms the passed in LibXML::Document object, and returns a
new LibXML::Document. Extra hash entries are used as parameters.
Be sure to keep in mind the caveat with regard to quotes explained in
the section on L</"Parameters"> below.
=end item

=begin item
transform(file => filename, |%params)

  my $results = $stylesheet.transform(file => $filename, bar => "'baz'");

Note the string parameter caveat, detailed in the section on
L</"Parameters"> below.
=end item

=begin item
.Xslt()

    my LibXSLT::Document::Xslt $results = .Xslt()
        given $stylesheet.transform($doc, foo => "'bar'");

Applies a role to serialize the
L<LibXML::Document> object using the desired output format
(specified in the xsl:output tag in the stylesheet).
=end item

=begin item
output-method()

Returns the value of the C<method> attribute from C<xsl:output>
(usually C<xml>, C<html> or C<text>). If this attribute is
unspecified, the default value is initially undefined. If the
C<transform> method is used to produce an HTML document, as per the
L<XSLT spec|http://www.w3.org/TR/xslt#output>, the default value will
change to C<html>. To override this behavior completely, supply an
C<xsl:output> element in the stylesheet source document.
=end item

=begin item
media-type()

Returns the value of the C<media-type> attribute from
C<xsl:output>. If this attribute is unspecified, the default media
type is initially undefined. This default changes to C<text/html>
under the same conditions as C<output-method>.
=end item

=begin item
input-callbacks($icb)

Enable the callbacks in C<$icb> only for this stylesheet. C<$icb>
should be a C<LibXML::InputCallback> object. This will call
C<init_callbacks> and C<cleanup_callbacks> automatically during
transformation.

=end item

=head1 Transform Parameters

Unlike the Perl 5 module, this Raku module automatically formats keys and parameters for xpath.

If you wish to emulate the Perl 5 behavour and/or format arguments yourself, pass :raw
to the `transform()` method. You can use `xpath-to-string()` function to do the
formatting:

  use LibXSLT::Stylesheet :&xpath-to-string;
  my %params = xpath-to-string(param => "string");
  $stylesheet.transform($doc, :raw, |%params);

The utility function does the right thing with respect to strings in XPath,
including when you have quotes already embedded within your string.


=end pod

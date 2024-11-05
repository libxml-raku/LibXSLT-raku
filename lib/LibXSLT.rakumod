unit class LibXSLT:ver<0.1.7>;

use LibXSLT::Stylesheet;
also is LibXSLT::Stylesheet;

use LibXSLT::Config;
use LibXSLT::Raw;
use LibXSLT::Raw::Defs :$XSLT;
use LibXML::Raw;
use LibXML::XPath::Context;
use LibXML::Types :NCName, :QName;
use Method::Also;
use NativeCall;

method config handles<have-exslt version config-version max-depth max-vars> {
    LibXSLT::Config;
}

method register-function(Str $url, QName:D $name, &func, |c) {
    xsltRegisterExtModuleFunction(
        $name, $url,
        -> xmlXPathParserContext $ctxt, Int $n {
            CATCH { default { note $_; $*XML-CONTEXT.callback-error: X::LibXML::XPath::AdHoc.new: :error($_) } }
            my @params;
            @params.unshift: LibXML::XPath::Context.get-value($ctxt.valuePop) for ^$n;
            my $ret = &func(|@params, |c) // '';
            my xmlXPathObject:D() $out = $*XML-CONTEXT.park($ret, :$ctxt);
            $ctxt.valuePush($_) for $out;
        }
    );
}

method set-debug-callback(&func) {
    xml6_gbl::set-generic-error-handler(
        -> Str $msg {
            CATCH { default { note $_; $*XML-CONTEXT.callback-error: X::LibXML::XPath::AdHoc.new: :error($_) } }
            &func($msg);
        },
        cglobal($XSLT, 'xsltSetGenericDebugFunc', Pointer)
    );
}

=begin pod

=head1 NAME

LibXSLT - Interface to the GNOME libxslt library

=head1 SYNOPSIS

  use LibXSLT;
  use LibXML::Document;

  # process a document with an internal '<?xml-stylesheet ..>' processing-instruction
  my LibXML::Document $doc .= parse(location => 'foo.xml');
  my Str $result = LibXSLT.process: :$doc;  

  # provide an external style-sheet
  my LibXML::Document $xsl .= parse(location => 'bar.xsl', :!cdata);
  my Str $result = LibXSLT.process: :$doc, :$xsl;

  # OO interface
  use LibXSLT::Document;
  use LibXSLT::Stylesheet;
  my LibXSLT $xslt .= new();

  my LibXSLT::Stylesheet $stylesheet;
  $stylesheet = $xslt.parse-stylesheet($xsl);
  # -OR-
  # get the stylesheet from a document's '<?xml-stylesheet ..>' processing-instruction
  $stylesheet .= load-stylesheet-pi(:$doc);

  my LibXSLT::Document::Xslt() $results = $stylesheet.transform(:$doc);
  say $results.Str;

=head1 DESCRIPTION

This module is an interface to the GNOME project's libxslt.

=head1 OPTIONS

LibXSLT has some global options. Note that these are probably not
thread or even fork safe - so only set them once per process. Each one
of these options can be called either as class methods, or as instance
methods. However either way you call them, it still sets global options.

Each of the option methods returns its previous value, and can be called
without a parameter to retrieve the current value.

=begin item
max-depth

  LibXSLT.max-depth = 1000;

This option sets the maximum recursion depth for a stylesheet. See the
very end of section 5.4 of the XSLT specification for more details on
recursion and detecting it. If your stylesheet or XML file requires
seriously deep recursion, this is the way to set it. Default value is
250.
=end item

=begin item
max-vars

  LibXSLT.max-vars = 100_000;

This option sets the maximum number of variables for a stylesheet. If your
stylesheet or XML file requires many variables, this is the way to increase
their limit. Default value is system-specific and may vary.
=end item

=begin item
set-debug-callback

  LibXSLT.set-debug-callback(&func ($fmt, *@args) );

Sets a callback to be used for debug messages. If you don't set this,
debug messages will be ignored.
=end item

=begin item
register-function

  LibXSLT.register-function($uri, $name, &func (|c) );
  $stylesheet.register-function($uri, $name, &func (|c) );

Registers an XSLT extension function mapped to the given URI. For example:

  LibXSLT.register-function("urn:foo", "date",
    sub { now.Date.Str });

Will register a C<date> function in the C<urn:foo> name-space (which you
have to define in your XSLT using C<xmlns:...>) that will return the
current date and time as a string:

  <xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:foo="urn:foo">
  <xsl:template match="/">
    The date is: <xsl:value-of select="foo:date()"/>
  </xsl:template>
  </xsl:stylesheet>

Parameters can be in whatever format you like. If you pass in a node-list
it will be a L<LibXML::Node::List> object in your Raku code, but ordinary
values (strings, numbers and booleans) may be passed. Return values can
be a node-list or a plain value - the code will just do the right thing.
But only a single return value is supported (a list is not converted to
a node-list).
=end item

=begin item
register-extension

        use LibXSLT::ExtensionContext;
	$stylesheet.register-extension($uri, $name, &func (LibXSLT::ExtensionContext) )

Registers an XSLT extension element $name mapped to the given URI. For example:

  use LibXSLT::ExtensionContext;
  $stylesheet.register-element("urn:foo", "hello", sub (LibXSLT::ExtensionContext $ctx) {
          my LibXML::Node $style = $ctx.style-node;
          my LibXML::Node $insert = $ctx.insert-node;
	  my $name = $style.getAttribute( "name" );
          $insert.addChild: LibXML::Text.new( "Hello, $name!" );
  });

Will register a C<hello> element in the C<urn:foo> name-space that inserts a "Hello, X!" text node. You must define this name-space in your XSLT and include its prefix in the C<extension-element-prefixes> list:

  <xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:foo="urn:foo"
	extension-element-prefixes="foo">
  <xsl:template match="/">
    <foo:hello name="bob"/>
  </xsl:template>
  </xsl:stylesheet>

A C<LibXSLT::ExtensionContext> object is passed, with three attributes:

  =item style-node() - The current input node from the stylesheet document

  =item source-node() - The current input node from the source document

  =item insert-node() - The current output node in the transformed document

=end item


=head1 API

The following methods are available on the LibXSLT class or object:

=begin item
process()

    my Str:D $result = LibXSLT.process: :$doc;
    my Str:D $result = LibXSLT.process: :$doc, :$xsl;

Processes a document using the document's `<?xml-stylesheet ... ?>` processing instruction
to locate and load a stylesheet.

Security handlers may be used to intercept access to external documents on the file-system or network (see below).
=end item

=begin item
load-stylesheet-pi()

    my LibXSLT::Stylesheet $xslt .= load-stylesheet-pi: :$doc;

Loads, but doesn't execute the stylesheet associated with the given document.
=end item

=begin item
parse-stylesheet($stylesheet-doc)

C<$stylesheet-doc> here is an L<LibXML::Document> object (see L<LibXML>)
representing an XSLT file. This method will return a
L<LibXSLT::Stylesheet> object. If the XSLT is
invalid, an exception will be thrown, so wrap the call to
parse_stylesheet in a try{} block to trap this.

IMPORTANT: C<$stylesheet-doc> should not contain CDATA sections,
otherwise libxslt may misbehave. The best way to assure this is to
load the stylesheet with `:!cdata` flag, e.g.

  my LibXML::Document $stylesheet-doc .= parse(location => "some.xsl", :!cdata);
=end item

=begin item
parse-stylesheet(file => $filename)

Exactly the same as the above, but parses the given filename directly.

=end item

=head1 Input Callbacks

To define LibXSLT or LibXSLT::Stylesheet specific input
callbacks, reuse the LibXML input callback API as described in
L<LibXML::InputCallback>.

=begin item
input-callbacks = $icb

Enable the callbacks in C<$icb> only for this LibXSLT object.
C<$icb> should be a L<LibXML::InputCallback> object. This will
call C<init_callbacks> and C<cleanup_callbacks> automatically during
parsing or transformation.

=end item

=head1 Security Callbacks

To create security preferences for the transformation see
L<LibXSLT::Security>. Once the security preferences have been defined you
can apply them to an LibXSLT or LibXSLT::Stylesheet instance using
the C<security-callbacks()> method.

=begin item
LibXSLT.have-exslt()

Returns True if the module was compiled with libexslt, False otherwise.

=end item

=head1 PREREQUISITES

This module requires the libxslt native library to be installed. Please follow the instructions below based on your platform:

=head2 Debian Linux

  sudo apt-get install libxslt-dev

=head2 Mac OS X

  brew update
  brew install libxslt

=head1 VERSION

0.1.0

=head1 LICENSE

This is free software, you may use it and distribute it under the same terms as
Perl itself.

Copyright 2001-2009, AxKit.com Ltd.

=head1 ACKNOWLEDGEMENTS

This Raku module is based on the Perl 5 XML::LibXSLT module. The `process()` method has
been adapted from the Perl 5 XML::LibXSL::Easy module.

With thanks to: Matt Sergeant, Shane Corgatelli, Petr Pal's, Shlomi Fish, יובל קוג'מן (Yuval Kogman)

=head1 SEE ALSO

L<LibXML>

=end pod

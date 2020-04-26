use v6;
use LibXSLT::Document; # help older Rakudos

use LibXSLT::Stylesheet;
unit class LibXSLT:ver<0.0.6>
    is LibXSLT::Stylesheet;

use LibXSLT::Config;
use LibXSLT::Native;
use LibXSLT::Native::Defs :$XSLT;
use LibXML::Native;
use LibXML::XPath::Context :get-value;
use LibXML::Types :NCName, :QName;
use LibXML::ErrorHandling :MsgArg, :&unmarshal-varargs;
use Method::Also;
use NativeCall;

method config handles<have-exslt version config-version max-depth max-vars> {
    LibXSLT::Config;
}

method register-function(Str $url, QName:D $name, &func, |c) {
    xsltRegisterExtModuleFunction(
        $name, $url,
        -> xmlXPathParserContext $ctxt, Int $n {
            CATCH { default { warn $_; $*XML-CONTEXT.callback-error: X::LibXML::XPath::AdHoc.new: :error($_) } }
            my @params;
            @params.unshift: get-value($ctxt.valuePop) for 0 ..^ $n;
            my $ret = &func(|@params, |c) // '';
            my xmlXPathObject:D $out := xmlXPathObject.coerce: $*XML-CONTEXT.park($ret, :$ctxt);
            $ctxt.valuePush($_) for $out;
        }
    );
}

sub set-debug-handler( &func (Str $fmt, Str $argt, Pointer[MsgArg] $argv), Pointer ) is native($XSLT) is symbol('xsltSetGenericDebugFunc') {*}

method set-debug-callback(&func) {
    set-debug-handler(
        -> Str $msg, Str $fmt, Pointer[MsgArg] $argv {
            CATCH { default { warn $_; $*XML-CONTEXT.callback-error: X::LibXML::XPath::AdHoc.new: :error($_) } }
            my @args = unmarshal-varargs($fmt, $argv);
            &func($msg, @args);
        },
        xml6_gbl_message_func
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

  my LibXSLT::Document::Xslt $results = $stylesheet.transform(:$doc).Xslt;
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
it will be a LibXML::Node::List object in your Raku code, but ordinary
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

C<$stylesheet-doc> here is an LibXML::Document object (see L<LibXML>)
representing an XSLT file. This method will return a
LibXSLT::Stylesheet object. If the XSLT is
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

=head1 LibXSLT::Stylesheet

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
LibXML::Document object using the desired output format
(specified in the xsl:output tag in the stylesheet).
=end item

=begin item
output-method()

Returns the value of the C<method> attribute from C<xsl:output>
(usually C<xml>, C<html> or C<text>). If this attribute is
unspecified, the default value is initially undefined. If the
L<transform> method is used to produce an HTML document, as per the
L<XSLT spec|http://www.w3.org/TR/xslt#output>, the default value will
change to C<html>. To override this behavior completely, supply an
C<xsl:output> element in the stylesheet source document.
=end item

=begin item
media-type()

Returns the value of the C<media-type> attribute from
C<xsl:output>. If this attribute is unspecified, the default media
type is initially undefined. This default changes to C<text/html>
under the same conditions as L<output_method>.
=end item

=begin item
input-callbacks($icb)

Enable the callbacks in C<$icb> only for this stylesheet. C<$icb>
should be a C<LibXML::InputCallback> object. This will call
C<init_callbacks> and C<cleanup_callbacks> automatically during
transformation.

=end item

=head1 Parameters

Unlike the Perl 5 module, this module automatically formats keys and parameters for xpath.

If you wish to emulate the Perl 5 behavour and/or format arguments yourself, pass :raw
to the `transform()` method. You can use `xpath-to-string()` function to do the
formatting:

  use LibXSLT::Stylesheet :&xpath-to-string;
  my %params = xpath-to-string(param => "string");
  $stylesheet.transform($doc, :raw, |%params);

The utility function does the right thing with respect to strings in XPath,
including when you have quotes already embedded within your string.


=head1 LibXSLT::Security

Provides an interface to the libxslt security framework by allowing callbacks
to be defined that can restrict access to various resources (files or URLs)
during a transformation.

The libxslt security framework allows callbacks to be defined for certain
actions that a stylesheet may attempt during a transformation. It may be
desirable to restrict some of these actions (for example, writing a new file
using exsl:document). The actions that may be restricted are:

=begin item
read-file

Called when the stylesheet attempts to open a local file (ie: when using the
document() function).
=end item

=begin item
write-file

Called when an attempt is made to write a local file (ie: when using the
exsl:document element).
=end item

=begin item
create-dir

Called when a directory needs to be created in order to write a file.

NOTE: By default, create_dir is not allowed. To enable it a callback must be
registered.
=end item

=begin item
read-net

Called when the stylesheet attempts to read from the network.
=end item

=begin item
write-net

Called when the stylesheet attempts to write to the network.

=end item

=head2 Using LibXSLT::Security

The interface for this module is similar to LibXML::InputCallback. After
creating a new instance you may register callbacks for each of the security
options listed above. Then you apply the security preferences to the
LibXSLT or LibXSLT::Stylesheet object using C<security_callbacks()>.

  my LibXSLT::Security $security .= new();
  $security.register-callback( read-file  => &read-cb );
  $security.register-callback( write-file => &write-cb );
  $security.register-callback( create-dir => &create-cb );
  $security.register-callback( read-net   => &read-net-cb );
  $security.register-callback( write-net  => &write-net-cb );

  $xslt.security-callbacks( $security );
   -OR-
  $stylesheet.security-callbacks( $security );


The registered callback functions are called when access to a resource is
requested. If the access should be allowed the callback should return True, if
not it should return False. The callback functions should accept the following
arguments:

=begin item
LibXSLT::TransformContext $tctxt

This is the transform context. You can use
this to get the current LibXSLT::Stylesheet object by calling
C<stylesheet()>.

  my $stylesheet = $tctxt.stylesheet();

The stylesheet object can then be used to share contextual information between
different calls to the security callbacks.
=end item

=begin item
Str $value

This is the name of the resource (file or URI) that has been requested.

=end item

If a particular option (except for C<create-dir>) doesn't have a registered
callback, then the stylesheet will have full access for that action.

=head2 Interface

=begin item
new()

Creates a new LibXSLT::Security object.
=end item

=begin item
register-callback( $option, &callback )

Registers a callback function for the given security option (listed above).
=end item

=begin item
unregister-callback( $option )

Removes the callback for the given option. This has the effect of allowing all
access for the given option (except for C<create_dir>).
=end item


=begin item
LibXSLT.have-exslt()

Returns True if the module was compiled with libexslt, False otherwise.

=end item

=head1 PREREQUISITES

This module requires the libxslt library to be installed. Please follow the instructions below based on your platform:

=head2 Debian Linux

  sudo apt-get install libxslt-dev

=head2 Mac OS X

  brew update
  brew install libxslt

=head1 VERSION

0.0.5

=head1 LICENSE

This is free software, you may use it and distribute it under the same terms as
Perl itself.

Copyright 2001-2009, AxKit.com Ltd.

=head1 ACKNOWLEDGEMENTS

This Raku module is based on the Perl 5 XML::LibXSLT module. The `process()` method has
been adapted from the Perl 5 XML::LibXSL::Easy module.

With thanks to: Matt Sergeant, Shane Corgatelli, Petr Pal's, Shlomi Fish, יובל קוג'מן (Yuval Kogman)

=head1 SEE ALSO

LibXML

=end pod

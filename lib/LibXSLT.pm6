use v6;
use LibXSLT::Document; # help Rakudo

use LibXSLT::Stylesheet;
unit class LibXSLT:ver<0.0.1>
    is LibXSLT::Stylesheet;

use LibXSLT::Config;
use LibXSLT::Native;
use LibXML::Native;
use LibXML::XPath::Context :get-value;
use LibXML::Types :NCName, :QName;
use Method::Also;

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

our sub xpath-to-string(*%xpath) {
    %xpath.map: {
        my $key = .key.subst(':', '_', :g);
        my $value = .value // '';
        my $string = $value ~~ s:g/\'/', "'", '/
            ?? "concat('$value')"
            !! "'{$value}'";
       $key => $string;
    }
}

=begin pod

=head1 NAME

LibXSLT - Interface to the GNOME libxslt library

=head1 SYNOPSIS

  use LibXSLT;
  use LibXML::Document;

  my LibXML::Document $xml .= parse(location => 'foo.xml');
  my LibXML::Document $xsl .= parse(location=>'bar.xsl', :!cdata);

  my Str $result = LibXSLT.process: :$xml, :$xsl;

  # OO interface
  use LibXSLT::Document;
  use LibXSLT::Stylesheet;
  my LibXSLT $xslt .= new();

  my LibXSLT::Stylesheet $stylesheet = $xslt.parse-stylesheet($xsl);
  my LibXSLT::Document::Xslt $results = $stylesheet.transform($xml).Xslt;
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

=over

=item max-depth

  LibXSLT.max-depth = 1000;

This option sets the maximum recursion depth for a stylesheet. See the
very end of section 5.4 of the XSLT specification for more details on
recursion and detecting it. If your stylesheet or XML file requires
seriously deep recursion, this is the way to set it. Default value is
250.

=item max-vars

  LibXSLT.max-vars = 100_000;

This option sets the maximum number of variables for a stylesheet. If your
stylesheet or XML file requires many variables, this is the way to increase
their limit. Default value is system-specific and may vary.

=item debug-callback

  LibXSLT.debug-callback($subref);

Sets a callback to be used for debug messages. If you don't set this,
debug messages will be ignored.

=item register-function

  LibXSLT.register-function($uri, $name, $subref);
  $stylesheet.register-function($uri, $name, $subref);

Registers an XSLT extension function mapped to the given URI. For example:

  LibXSLT.register-function("urn:foo", "date",
    sub { now.Date.Str });

Will register a C<date> function in the C<urn:foo> namespace (which you
have to define in your XSLT using C<xmlns:...>) that will return the
current date and time as a string:

  <xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:foo="urn:foo">
  <xsl:template match="/">
    The date is: <xsl:value-of select="foo:date()"/>
  </xsl:template>
  </xsl:stylesheet>

Parameters can be in whatever format you like. If you pass in a nodelist
it will be a LibXML::Node::List object in your Perl code, but ordinary
values (strings, numbers and booleans) may be passed. Return values can
be a nodelist or a plain value - the code will just do the right thing.
But only a single return value is supported (a list is not converted to
a nodelist).

=item register-extension

	$stylesheet.register_element($uri, $name, $subref)

Registers an XSLT extension element $name mapped to the given URI. For example:

  use LibXSLT::ExtensionContext;
  $stylesheet.register_element("urn:foo", "hello", sub (LibXSLT::ExtensionContext $ctx) {
          my LibXML::Node $style = $ctx.style-node;
          my LibXML::Node $insert = $ctx.insert-node;
	  my $name = $style.getAttribute( "name" );
          $insert.addChild: LibXML::Text.new( "Hello, $name!" );
  });

Will register a C<hello> element in the C<urn:foo> namespace that returns a "Hello, X!" text node. You must define this namespace in your XSLT and include its prefix in the C<extension-element-prefixes> list:

  <xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:foo="urn:foo"
	extension-element-prefixes="foo">
  <xsl:template match="/">
    <foo:hello name="bob"/>
  </xsl:template>
  </xsl:stylesheet>

A C<LibXSLT::ExtensionContext> object is passed, giving details of the input style-node and source-node and the current output insert node.

=back

=head1 API

The following methods are available on the new LibXSLT object:

=over

=item parse-stylesheet($stylesheet-doc)

C<$stylesheet-doc> here is an LibXML::Document object (see L<LibXML>)
representing an XSLT file. This method will return a
LibXSLT::Stylesheet object, or undef on failure. If the XSLT is
invalid, an exception will be thrown, so wrap the call to
parse_stylesheet in a try{} block to trap this.

IMPORTANT: C<$stylesheet-doc> should not contain CDATA sections,
otherwise libxslt may misbehave. The best way to assure this is to
load the stylesheet with no_cdata flag, e.g.

  my $stylesheet_doc = LibXML.load_xml(location=>"some.xsl", !cdata);

=item parse_stylesheet-file($filename)

Exactly the same as the above, but parses the given filename directly.

=back

=head1 Input Callbacks

To define LibXSLT or LibXSLT::Stylesheet specific input
callbacks, reuse the LibXML input callback API as described in
L<LibXML::InputCallback(3)>.

=over 4

=item input-callbacks($icb)

Enable the callbacks in C<$icb> only for this LibXSLT object.
C<$icb> should be a C<LibXML::InputCallback> object. This will
call C<init_callbacks> and C<cleanup_callbacks> automatically during
parsing or transformation.

=back

=head1 Security Callbacks

To create security preferences for the transformation see
L<LibXSLT::Security>. Once the security preferences have been defined you
can apply them to an LibXSLT or LibXSLT::Stylesheet instance using
the C<security_callbacks()> method.

=head1 LibXSLT::Stylesheet

The main API is on the stylesheet, though it is fairly minimal.

One of the main advantages of LibXSLT is that you have a generic
stylesheet object which you call the transform() method passing in a
document to transform. This allows you to have multiple transformations
happen with one stylesheet without requiring a reparse.

=over

=item transform(doc, %params)

  my $results = $stylesheet.transform($doc, foo => "'bar'");
  print $results.Xslt.Str;

Transforms the passed in LibXML::Document object, and returns a
new LibXML::Document. Extra hash entries are used as parameters.
Be sure to keep in mind the caveat with regard to quotes explained in
the section on L</"Parameters"> below.

=item transform-file(filename, %params)

  my $results = $stylesheet.transform-file($filename, bar => "'baz'");

Note the string parameter caveat, detailed in the section on
L</"Parameters"> below.

=item .Xslt

    my LibXSLT::Document::Xslt $results = .Xslt
        given $stylesheet.transform($doc, foo => "'bar'");

Applies a role to serialize the
LibXML::Document object using the desired output format
(specified in the xsl:output tag in the stylesheet).

=item output-fh(result, fh)

Outputs the result to the filehandle given in C<$fh>.

=item output-file(result, filename)

Outputs the result to the file named in C<$filename>.

=item output-encoding()

Returns the output encoding of the results. Defaults to "UTF-8".

=item output-method()

Returns the value of the C<method> attribute from C<xsl:output>
(usually C<xml>, C<html> or C<text>). If this attribute is
unspecified, the default value is initially C<xml>. If the
L<transform> method is used to produce an HTML document, as per the
L<XSLT spec|http://www.w3.org/TR/xslt#output>, the default value will
change to C<html>. To override this behavior completely, supply an
C<xsl:output> element in the stylesheet source document.

=item media-type()

Returns the value of the C<media-type> attribute from
C<xsl:output>. If this attribute is unspecified, the default media
type is initially C<text/xml>. This default changes to C<text/html>
under the same conditions as L<output_method>.

=item input-callbacks($icb)

Enable the callbacks in C<$icb> only for this stylesheet. C<$icb>
should be a C<LibXML::InputCallback> object. This will call
C<init_callbacks> and C<cleanup_callbacks> automatically during
transformation.

=back

=cut

=head1 Parameters

LibXSLT expects parameters in XPath format. That is, if you wish to pass
a string to the XSLT engine, you actually have to pass it as a quoted
string:

  $stylesheet.transform($doc, param => "'string'");

Note the quotes within quotes there!

Obviously this isn't much fun, so you can make it easy on yourself:

  $stylesheet.transform($doc, LibXSLT::xpath-to-string(
        param => "string"
        ));

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

=over

=item read-file

Called when the stylesheet attempts to open a local file (ie: when using the
document() function).

=item write-file

Called when an attempt is made to write a local file (ie: when using the
exsl:document element).

=item create-dir

Called when a directory needs to be created in order to write a file.

NOTE: By default, create_dir is not allowed. To enable it a callback must be
registered.

=item read-net

Called when the stylesheet attempts to read from the network.

=item write-net

Called when the stylesheet attempts to write to the network.

=back

=head2 Using LibXSLT::Security

The interface for this module is similar to LibXML::InputCallback. After
creating a new instance you may register callbacks for each of the security
options listed above. Then you apply the security preferences to the
LibXSLT or LibXSLT::Stylesheet object using C<security_callbacks()>.

  my $security = LibXSLT::Security.new();
  $security.register-callback( read-file  => $read-cb );
  $security.register-callback( write-file => $write-cb );
  $security.register-callback( create-dir => $create-cb );
  $security.register-callback( read-net   => $read-net-cb );
  $security.register-callback( write-net  => $write-net-cb );

  $xslt.security-callbacks( $security );
   -OR-
  $stylesheet.security-callbacks( $security );


The registered callback functions are called when access to a resource is
requested. If the access should be allowed the callback should return True, if
not it should return False. The callback functions should accept the following
arguments:

=over

=item $tctxt

This is the transform context (LibXSLT::TransformContext). You can use
this to get the current LibXSLT::Stylesheet object by calling
C<stylesheet()>.

  my $stylesheet = $tctxt.stylesheet();

The stylesheet object can then be used to share contextual information between
different calls to the security callbacks.

=item $value

This is the name of the resource (file or URI) that has been requested.

=back

If a particular option (except for C<create-dir>) doesn't have a registered
callback, then the stylesheet will have full access for that action.

=head2 Interface

=over

=item new()

Creates a new LibXSLT::Security object.

=item register-callback( $option, $callback )

Registers a callback function for the given security option (listed above).

=item unregister-callback( $option )

Removes the callback for the given option. This has the effect of allowing all
access for the given option (except for C<create_dir>).

=back

=item LibXSLT.havel-exlt()

Returns 1 if the module was compiled with libexslt, 0 otherwise.

=back

=head1 LICENSE

This is free software, you may use it and distribute it under the same terms as
Perl itself.

Copyright 2001-2009, AxKit.com Ltd.

=head1 CONTRIBUTERS

With thanks to: Matt Sergeant, Shane Corgatelli, Petr Pajas, Shlomi Fish, יובל קוג'מן (Yuval Kogman)

=head1 SEE ALSO

LibXML

=end pod

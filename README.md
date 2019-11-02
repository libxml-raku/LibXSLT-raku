[![Build Status](https://travis-ci.org/p6-xml/LibXSLT-raku.svg?branch=master)](https://travis-ci.org/p6-xml/LibXSLT-raku)

NAME
====

LibXSLT - Interface to the GNOME libxslt library

SYNOPSIS
========

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

DESCRIPTION
===========

This module is an interface to the GNOME project's libxslt.

OPTIONS
=======

LibXSLT has some global options. Note that these are probably not thread or even fork safe - so only set them once per process. Each one of these options can be called either as class methods, or as instance methods. However either way you call them, it still sets global options.

Each of the option methods returns its previous value, and can be called without a parameter to retrieve the current value.

  * max-depth

        LibXSLT.max-depth = 1000;

    This option sets the maximum recursion depth for a stylesheet. See the very end of section 5.4 of the XSLT specification for more details on recursion and detecting it. If your stylesheet or XML file requires seriously deep recursion, this is the way to set it. Default value is 250.

  * max-vars

        LibXSLT.max-vars = 100_000;

    This option sets the maximum number of variables for a stylesheet. If your stylesheet or XML file requires many variables, this is the way to increase their limit. Default value is system-specific and may vary.

  * set-debug-callback

        LibXSLT.set-debug-callback(&func ($fmt, *@args) );

    Sets a callback to be used for debug messages. If you don't set this, debug messages will be ignored.

  * register-function

        LibXSLT.register-function($uri, $name, &func (|c) );
        $stylesheet.register-function($uri, $name, &func (|c) );

    Registers an XSLT extension function mapped to the given URI. For example:

        LibXSLT.register-function("urn:foo", "date",
          sub { now.Date.Str });

    Will register a `date` function in the `urn:foo` name-space (which you have to define in your XSLT using `xmlns:...`) that will return the current date and time as a string:

        <xsl:stylesheet version="1.0"
          xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
          xmlns:foo="urn:foo">
        <xsl:template match="/">
          The date is: <xsl:value-of select="foo:date()"/>
        </xsl:template>
        </xsl:stylesheet>

    Parameters can be in whatever format you like. If you pass in a node-list it will be a LibXML::Node::List object in your Perl code, but ordinary values (strings, numbers and booleans) may be passed. Return values can be a node-list or a plain value - the code will just do the right thing. But only a single return value is supported (a list is not converted to a node-list).

  * register-extension

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

    Will register a `hello` element in the `urn:foo` name-space that inserts a "Hello, X!" text node. You must define this name-space in your XSLT and include its prefix in the `extension-element-prefixes` list:

        <xsl:stylesheet version="1.0"
          xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
          xmlns:foo="urn:foo"

        extension-element-prefixes="foo">

        <xsl:template match="/">
          <foo:hello name="bob"/>
        </xsl:template>
        </xsl:stylesheet>

    A `LibXSLT::ExtensionContext` object is passed, with three attributes:

      * style-node() - The current input node from the stylesheet document

      * source-node() - The current input node from the source document

      * insert-node() - The current output node in the transformed document

API
===

The following methods are available on the LibXSLT class or object:

  * process()

        my Str:D $result = LibXSLT.process: :$doc;
        my Str:D $result = LibXSLT.process: :$doc, :$xsl;

    Processes a document using the document's `<?xml-stylesheet ... ?>` processing instruction to locate and load a stylesheet.

    Security handlers may be used to intercept access to external documents on the file-system or network (see below).

  * load-stylesheet-pi()

        my LibXSLT::Stylesheet $xslt .= load-stylesheet-pi: :$doc;

    Loads, but doesn't execute the stylesheet associated with the given document.

  * parse-stylesheet($stylesheet-doc)

    `$stylesheet-doc` here is an LibXML::Document object (see [LibXML](LibXML)) representing an XSLT file. This method will return a LibXSLT::Stylesheet object. If the XSLT is invalid, an exception will be thrown, so wrap the call to parse_stylesheet in a try{} block to trap this.

    IMPORTANT: `$stylesheet-doc` should not contain CDATA sections, otherwise libxslt may misbehave. The best way to assure this is to load the stylesheet with `:!cdata` flag, e.g.

        my LibXML::Document $stylesheet-doc .= parse(location => "some.xsl", :!cdata);

  * parse-stylesheet(file => $filename)

    Exactly the same as the above, but parses the given filename directly.

Input Callbacks
===============

To define LibXSLT or LibXSLT::Stylesheet specific input callbacks, reuse the LibXML input callback API as described in [LibXML::InputCallback](LibXML::InputCallback).

  * input-callbacks = $icb

    Enable the callbacks in `$icb` only for this LibXSLT object. `$icb` should be a [LibXML::InputCallback](LibXML::InputCallback) object. This will call `init_callbacks` and `cleanup_callbacks` automatically during parsing or transformation.

Security Callbacks
==================

To create security preferences for the transformation see [LibXSLT::Security](LibXSLT::Security). Once the security preferences have been defined you can apply them to an LibXSLT or LibXSLT::Stylesheet instance using the `security-callbacks()` method.

LibXSLT::Stylesheet
===================

The main API is on the stylesheet, though it is fairly minimal.

One of the main advantages of LibXSLT is that you have a generic stylesheet object which you call the `transform()` method passing in a document to transform. This allows you to have multiple transformations happen with one stylesheet without requiring a reparse.

  * transform(:$doc, %params)

        my $results = $stylesheet.transform(:$doc, foo => "'bar'");
        print $results.Xslt.Str;

    Transforms the passed in LibXML::Document object, and returns a new LibXML::Document. Extra hash entries are used as parameters. Be sure to keep in mind the caveat with regard to quotes explained in the section on [/"Parameters"](/"Parameters") below.

  * transform(file => filename, |%params)

        my $results = $stylesheet.transform(file => $filename, bar => "'baz'");

    Note the string parameter caveat, detailed in the section on [/"Parameters"](/"Parameters") below.

  * .Xslt()

        my LibXSLT::Document::Xslt $results = .Xslt()
            given $stylesheet.transform($doc, foo => "'bar'");

    Applies a role to serialize the LibXML::Document object using the desired output format (specified in the xsl:output tag in the stylesheet).

  * output-method()

    Returns the value of the `method` attribute from `xsl:output` (usually `xml`, `html` or `text`). If this attribute is unspecified, the default value is initially undefined. If the [transform](transform) method is used to produce an HTML document, as per the [XSLT spec](http://www.w3.org/TR/xslt#output), the default value will change to `html`. To override this behavior completely, supply an `xsl:output` element in the stylesheet source document.

  * media-type()

    Returns the value of the `media-type` attribute from `xsl:output`. If this attribute is unspecified, the default media type is initially undefined. This default changes to `text/html` under the same conditions as [output_method](output_method).

  * input-callbacks($icb)

    Enable the callbacks in `$icb` only for this stylesheet. `$icb` should be a `LibXML::InputCallback` object. This will call `init_callbacks` and `cleanup_callbacks` automatically during transformation.

Parameters
==========

LibXSLT expects parameters in XPath format. That is, if you wish to pass a string to the XSLT engine, you actually have to pass it as a quoted string:

    $stylesheet.transform($doc, param => "'string'");

Note the quotes within quotes there!

Obviously this isn't much fun, so you can make it easy on yourself:

    my @params = LibXSLT::xpath-to-string(param => "string");
    $stylesheet.transform($doc, |@params);

The utility function does the right thing with respect to strings in XPath, including when you have quotes already embedded within your string.

LibXSLT::Security
=================

Provides an interface to the libxslt security framework by allowing callbacks to be defined that can restrict access to various resources (files or URLs) during a transformation.

The libxslt security framework allows callbacks to be defined for certain actions that a stylesheet may attempt during a transformation. It may be desirable to restrict some of these actions (for example, writing a new file using exsl:document). The actions that may be restricted are:

  * read-file

    Called when the stylesheet attempts to open a local file (ie: when using the document() function).

  * write-file

    Called when an attempt is made to write a local file (ie: when using the exsl:document element).

  * create-dir

    Called when a directory needs to be created in order to write a file.

    NOTE: By default, create_dir is not allowed. To enable it a callback must be registered.

  * read-net

    Called when the stylesheet attempts to read from the network.

  * write-net

    Called when the stylesheet attempts to write to the network.

Using LibXSLT::Security
-----------------------

The interface for this module is similar to LibXML::InputCallback. After creating a new instance you may register callbacks for each of the security options listed above. Then you apply the security preferences to the LibXSLT or LibXSLT::Stylesheet object using `security_callbacks()`.

    my LibXSLT::Security $security .= new();
    $security.register-callback( read-file  => &read-cb );
    $security.register-callback( write-file => &write-cb );
    $security.register-callback( create-dir => &create-cb );
    $security.register-callback( read-net   => &read-net-cb );
    $security.register-callback( write-net  => &write-net-cb );

    $xslt.security-callbacks( $security );
     -OR-
    $stylesheet.security-callbacks( $security );

The registered callback functions are called when access to a resource is requested. If the access should be allowed the callback should return True, if not it should return False. The callback functions should accept the following arguments:

  * LibXSLT::TransformContext $tctxt

    This is the transform context. You can use this to get the current LibXSLT::Stylesheet object by calling `stylesheet()`.

        my $stylesheet = $tctxt.stylesheet();

    The stylesheet object can then be used to share contextual information between different calls to the security callbacks.

  * Str $value

    This is the name of the resource (file or URI) that has been requested.

If a particular option (except for `create-dir`) doesn't have a registered callback, then the stylesheet will have full access for that action.

Interface
---------

  * new()

    Creates a new LibXSLT::Security object.

  * register-callback( $option, &callback )

    Registers a callback function for the given security option (listed above).

  * unregister-callback( $option )

    Removes the callback for the given option. This has the effect of allowing all access for the given option (except for `create_dir`).

  * LibXSLT.have-exslt()

    Returns True if the module was compiled with libexslt, False otherwise.

PREREQUISITES
=============

This module requires the libxslt library to be installed. Please follow the instructions below based on your platform:

Debian Linux
------------

    sudo apt-get install libxslt-dev

Mac OS X
--------

    brew update
    brew install libxslt

VERSION
=======

0.0.5

LICENSE
=======

This is free software, you may use it and distribute it under the same terms as Perl itself.

Copyright 2001-2009, AxKit.com Ltd.

CONTRIBUTERS
============

This Raku module is based on the Perl 5 XML::LibXSLT module. The `process()` method has been adapted from the XML::LibXSL::Easy module.

With thanks to: Matt Sergeant, Shane Corgatelli, Petr Pal's, Shlomi Fish, יובל קוג'מן (Yuval Kogman)

SEE ALSO
========

LibXML


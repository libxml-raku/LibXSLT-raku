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

    Parameters can be in whatever format you like. If you pass in a node-list it will be a [LibXML::Node::List](https://libxml-raku.github.io/LibXML-raku/Node/List) object in your Raku code, but ordinary values (strings, numbers and booleans) may be passed. Return values can be a node-list or a plain value - the code will just do the right thing. But only a single return value is supported (a list is not converted to a node-list).

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

    `$stylesheet-doc` here is an [LibXML::Document](https://libxml-raku.github.io/LibXML-raku/Document) object (see [LibXML](https://libxml-raku.github.io/LibXML-raku)) representing an XSLT file. This method will return a [LibXSLT::Stylesheet](https://libxml-raku.github.io/LibXSLT-raku/Stylesheet) object. If the XSLT is invalid, an exception will be thrown, so wrap the call to parse_stylesheet in a try{} block to trap this.

    IMPORTANT: `$stylesheet-doc` should not contain CDATA sections, otherwise libxslt may misbehave. The best way to assure this is to load the stylesheet with `:!cdata` flag, e.g.

        my LibXML::Document $stylesheet-doc .= parse(location => "some.xsl", :!cdata);

  * parse-stylesheet(file => $filename)

    Exactly the same as the above, but parses the given filename directly.

Input Callbacks
===============

To define LibXSLT or LibXSLT::Stylesheet specific input callbacks, reuse the LibXML input callback API as described in [LibXML::InputCallback](https://libxml-raku.github.io/LibXML-raku/InputCallback).

  * input-callbacks = $icb

    Enable the callbacks in `$icb` only for this LibXSLT object. `$icb` should be a [LibXML::InputCallback](https://libxml-raku.github.io/LibXML-raku/InputCallback) object. This will call `init_callbacks` and `cleanup_callbacks` automatically during parsing or transformation.

Security Callbacks
==================

To create security preferences for the transformation see [LibXSLT::Security](https://libxml-raku.github.io/LibXSLT-raku/Security). Once the security preferences have been defined you can apply them to an LibXSLT or LibXSLT::Stylesheet instance using the `security-callbacks()` method.

  * LibXSLT.have-exslt()

    Returns True if the module was compiled with libexslt, False otherwise.

PREREQUISITES
=============

This module requires the libxslt native library to be installed. Please follow the instructions below based on your platform:

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

ACKNOWLEDGEMENTS
================

This Raku module is based on the Perl 5 XML::LibXSLT module. The `process()` method has been adapted from the Perl 5 XML::LibXSL::Easy module.

With thanks to: Matt Sergeant, Shane Corgatelli, Petr Pal's, Shlomi Fish, יובל קוג'מן (Yuval Kogman)

SEE ALSO
========

[LibXML](https://libxml-raku.github.io/LibXML-raku)


NAME
====

LibXSLT::Stylesheet

DESCRIPTION
===========

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

    Applies a role to serialize the [LibXML::Document](https://libxml-raku.github.io/LibXML-raku/Document) object using the desired output format (specified in the xsl:output tag in the stylesheet).

  * output-method()

    Returns the value of the `method` attribute from `xsl:output` (usually `xml`, `html` or `text`). If this attribute is unspecified, the default value is initially undefined. If the `transform` method is used to produce an HTML document, as per the [XSLT spec](http://www.w3.org/TR/xslt#output), the default value will change to `html`. To override this behavior completely, supply an `xsl:output` element in the stylesheet source document.

  * media-type()

    Returns the value of the `media-type` attribute from `xsl:output`. If this attribute is unspecified, the default media type is initially undefined. This default changes to `text/html` under the same conditions as `output-method`.

  * input-callbacks($icb)

    Enable the callbacks in `$icb` only for this stylesheet. `$icb` should be a `LibXML::InputCallback` object. This will call `init_callbacks` and `cleanup_callbacks` automatically during transformation.

Transform Parameters
====================

Unlike the Perl 5 module, this Raku module automatically formats keys and parameters for xpath.

If you wish to emulate the Perl 5 behavour and/or format arguments yourself, pass :raw to the `transform()` method. You can use `xpath-to-string()` function to do the formatting:

    use LibXSLT::Stylesheet :&xpath-to-string;
    my %params = xpath-to-string(param => "string");
    $stylesheet.transform($doc, :raw, |%params);

The utility function does the right thing with respect to strings in XPath, including when you have quotes already embedded within your string.


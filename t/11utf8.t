use v6;
use Test;
plan 3;

use LibXSLT;
use LibXSLT::Document;
use LibXML;
use LibXML::Document;

my LibXML:D $parser .= new;
my LibXSLT:D $xslt .= new;

subtest 'default document encoding', {
    # U+0100 == LATIN CAPITAL LETTER A WITH MACRON
    my LibXML::Document:D $doc = $parser.parse: :string(q:to<XML>);
    <unicode>Ādam</unicode>
    XML
    is $doc.textContent, 'Ādam';

    my LibXML::Document:D $style_doc = $parser.parse: :string(q:to<XSLT>);
    <xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:output method="text" encoding="UTF-8"/>
      <xsl:template match="/unicode">
        <xsl:value-of select="."/>
      </xsl:template>
    </xsl:stylesheet>
    XSLT

    my LibXSLT:D $stylesheet = $xslt.parse-stylesheet($style_doc);
    my LibXSLT::Document::Xslt:D() $results = $stylesheet.transform($doc);

    my $output = $results.Str;
    ok $output;

    # Test that we've correctly converted to characters seeing as the
    # output format was UTF-8.

    is $output, "Ādam";

    $output = $results.Str;
    is $output, "Ādam";

    $output = $results.Blob;
    is-deeply $output.decode,  "Ādam";
}

# LATIN-2 character 17E - z caron
my LibXML::Document:D $doc = $parser.parse: :string(q:to<XML>);
<?xml version="1.0" encoding="UTF-8"?>
<unicode>žil</unicode>
XML

# no encoding: libxslt chooses either an entity or UTF-8
subtest 'default output encoding', {
    my $style_doc = $parser.parse: :string(q:to<XSLT>);
    <xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:output method="text"/>
      <xsl:template match="/unicode">
        <xsl:value-of select="."/>
      </xsl:template>
    </xsl:stylesheet>
    XSLT
    ok $style_doc;
    my LibXSLT:D $stylesheet = $xslt.parse-stylesheet($style_doc);
    my LibXSLT::Document::Xslt:D() $results = $stylesheet.transform($doc);

    my $output = $results.Str;
    ok $output ~~ /^['&#382'|'ž']il/;

    like $output, /^['&#382'|'ž']il/;
}

subtest 'iso-8859-1 encoding', {
    my LibXML::Document:D $style_doc = $parser.parse: :string(q:to<XSLT>);
    <xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:output method="text" encoding="iso-8859-1"/>
      <xsl:template match="/unicode">
        <xsl:value-of select="."/>
      </xsl:template>
    </xsl:stylesheet>
    XSLT
    my LibXSLT:D $stylesheet = $xslt.parse-stylesheet($style_doc);
    my LibXSLT::Document::Xslt:D() $results = $stylesheet.transform($doc);
    my $output = $results.Str;
    is $output, '&#382;il';

    $output = $results.Blob;
    is $output.decode, '&#382;il';
}

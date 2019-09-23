use v6;
use Test;
plan 20;

use LibXSLT;
use LibXML;

my $parser = LibXML.new();
# TEST
ok( $parser, ' TODO : Add test name' );

my $xslt = LibXSLT.new();

{
# U+0100 == LATIN CAPITAL LETTER A WITH MACRON
my $doc = $parser.parse: :string(q:to<XML>);
<unicode>Ādam</unicode>
XML
# TEST
ok( $doc, ' TODO : Add test name' );

my $style_doc = $parser.parse: :string(q:to<XSLT>);
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:template match="/unicode">
    <xsl:value-of select="."/>
  </xsl:template>
</xsl:stylesheet>
XSLT
# TEST
ok( $style_doc, ' TODO : Add test name' );

my $stylesheet = $xslt.parse-stylesheet($style_doc);
# TEST
ok( $stylesheet, ' TODO : Add test name' );

my $results = $stylesheet.transform($doc).Xslt;
# TEST
ok( $results, ' TODO : Add test name' );

my $output = $results.Str;
# TEST
ok( $output, ' TODO : Add test name' );

# Test that we've correctly converted to characters seeing as the
# output format was UTF-8.

# TEST
# TEST
is( $output, "Ādam", ' TODO : Add test name' );

$output = $results.Str;
# TEST
# TEST
is( $output, "Ādam", ' TODO : Add test name' );

$output = $results.Blob;
# TEST
# TEST
is-deeply( $output.decode,  "\x[0100]dam",  ' TODO : Add test name' );
}

# LATIN-2 character 17E - z caron
my $doc = $parser.parse: :string(q:to<XML>);
<?xml version="1.0" encoding="UTF-8"?>
<unicode>žil</unicode>
XML
# TEST
ok( $doc, ' TODO : Add test name' );

# no encoding: libxslt chooses either an entity or UTF-8
{
  my $style_doc = $parser.parse: :string(q:to<XSLT>);
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text"/>
  <xsl:template match="/unicode">
    <xsl:value-of select="."/>
  </xsl:template>
</xsl:stylesheet>
XSLT
  # TEST
  ok( $style_doc, ' TODO : Add test name' );
  my $stylesheet = $xslt.parse-stylesheet($style_doc);
  # TEST
  ok( $stylesheet, ' TODO : Add test name' );
  my $results = $stylesheet.transform($doc).Xslt;
  # TEST
  ok( $results, ' TODO : Add test name' );

  my $output = $results.Str;
  # TEST
  # TEST
  ok( $output ~~ /^['&#382'|'ž']il/, ' TODO : Add test name' );

  like( $output, /^['&#382'|'ž']il/, ' TODO : Add test name' );
}

# doesn't map to latin-1 so will appear as an entity
{
  my $style_doc = $parser.parse: :string(q:to<XSLT>);
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="iso-8859-1"/>
  <xsl:template match="/unicode">
    <xsl:value-of select="."/>
  </xsl:template>
</xsl:stylesheet>
XSLT
  # TEST
  ok( $style_doc, ' TODO : Add test name' );
  my $stylesheet = $xslt.parse-stylesheet($style_doc);
  # TEST
  ok( $stylesheet, ' TODO : Add test name' );
  my $results = $stylesheet.transform($doc).Xslt;
  # TEST
  ok( $results, ' TODO : Add test name' );
  my $output = $results.Str;
  # TEST
  ok( $output, ' TODO : Add test name' );

  # TEST

  $output = $results.Blob;
  # TEST
  is( $output.decode, '&#382;il', ' TODO : Add test name' );
}

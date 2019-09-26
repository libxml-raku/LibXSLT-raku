use v6;
use Test;
plan 27;

use LibXSLT;
use LibXML;
# TEST
ok(1, ' TODO : Add test name');

my $bad_xsl1 = 'example/bad1.xsl';
my $bad_xsl2 = 'example/bad2.xsl';
my $bad_xsl3 = 'example/bad3.xsl';
my $fatal_xsl = 'example/fatal.xsl';
my $nonfatal_xsl = 'example/nonfatal.xsl';
my $good_xsl = 'example/1.xsl';
my $good_xml = 'example/1.xml';
my $bad_xml  = 'example/bad2.xsl';

my $xslt = LibXSLT.new;
# TEST
ok($xslt, ' TODO : Add test name');

{
    my $stylesheet = LibXML.parse: :file($bad_xsl1);
    dies-ok { $xslt.parse-stylesheet($stylesheet) }, ' TODO : Add test name';
}

dies-ok { LibXML.parse: :file($bad_xsl2) }, ' TODO : Add test name';

{
  my $stylesheet = LibXML.parse: :file($good_xsl);
  # TEST
  ok( $stylesheet, ' TODO : Add test name' );
  my $parsed = $xslt.parse-stylesheet( $stylesheet );
  # TEST
  ok( $parsed, ' TODO : Add test name' );
  try { $parsed.transform_file( $bad_xml ); };
  # TEST
  ok( $!, ' TODO : Add test name' );
}

{
  my $stylesheet = LibXML.new.parse: :file($nonfatal_xsl);
  # TEST
  ok( $stylesheet, ' TODO : Add test name' );
  my $parsed = $xslt.parse-stylesheet( $stylesheet );
  # TEST
  ok( $parsed, ' TODO : Add test name' );
  try { $parsed.transform: :file( $good_xml ); };
  # TEST
  like( $!.message, /'parser error : Non-fatal message.'/, ' TODO : Add test name' )
      or diag "unexpected error: $!";
}

{
  my $parser = LibXML.new;
  my $stylesheet = $parser.parse: :file($bad_xsl3);
  # TEST
  ok( $stylesheet, ' TODO : Add test name' );
  my $parsed = $xslt.parse-stylesheet( $stylesheet );
  # TEST
  ok( $parsed, ' TODO : Add test name' );
  try { $parsed.transform_file( $good_xml ); };
  # TEST
  ok( $!, ' TODO : Add test name' );
  my $dom = $parser.parse: :file( $good_xml );
  # TEST
  ok( $dom, ' TODO : Add test name' );
  try { $parsed.transform( $dom ); };
  # TEST
  ok( $!, ' TODO : Add test name' );
}

{
  my $parser = LibXML.new;
  my $stylesheet = $parser.parse: :file($fatal_xsl);
  # TEST
  ok( $stylesheet, ' TODO : Add test name' );
  my $parsed = $xslt.parse-stylesheet( $stylesheet );
  # TEST
  ok( $parsed, ' TODO : Add test name' );
  try { $parsed.transform_file( $good_xml ); };
  # TEST
  ok( $!, ' TODO : Add test name' );
  my $dom = $parser.parse: :file( $good_xml );
  # TEST
  ok( $dom, ' TODO : Add test name' );
  try { $parsed.transform( $dom ); };
  # TEST
  ok( $!, ' TODO : Add test name' );
}

{
my $parser = LibXML.new();
# TEST
ok( $parser, ' TODO : Add test name' );

my $doc = $parser.parse: :string(q:to<XML>);
<doc/>
XML
# TEST
ok( $doc, ' TODO : Add test name' );

my $xslt = LibXSLT.new();
my $style_doc = $parser.parse: :string(q:to<XSLT>);
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    <xsl:value-of select="$foo"/>
  </xsl:template>
</xsl:stylesheet>
XSLT
# TEST
ok( $style_doc, ' TODO : Add test name' );

my $stylesheet = $xslt.parse-stylesheet($style_doc);
# TEST
ok( $stylesheet, ' TODO : Add test name' );

my $results;
try {
$results = $stylesheet.transform($doc); };

my $E = $!;
# TEST
ok( $E, ' TODO : Add test name' );

# TEST
like( $E.message,
    rx:i/'unregistered variable foo'|"variable 'foo' has not been declared"/,
    'Exception matches.' );
# TEST
like( $E.message, /'element value-of'/, 'Exception matches "element value-of"' );
}

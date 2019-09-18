use v6;
use Test;
plan 12;
use LibXSLT;
use LibXML;

# this test is here because Mark Cox found a segfault
# that occurs when parse-stylesheet is immediately followed
# by a transform()

my $parser = LibXML.new();
my $xslt = LibXSLT.new();
# TEST
ok($parser, ' TODO : Add test name'); # TEST
 ok($xslt, ' TODO : Add test name');
my $source = $parser.parse: :file('example/1.xml');
# TEST
ok($source, ' TODO : Add test name');

my ($out1, $out2);

{
my $style_doc = $parser.parse: :file('example/1.xsl');
my $stylesheet = $xslt.parse-stylesheet($style_doc);
my $results = $stylesheet.transform(:doc($source));
$out1 = $results.Str-xslt;
# TEST
ok($out1, ' TODO : Add test name');
}

{
$source = $parser.parse: :file('example/2.xml');
# TEST
ok($source, ' TODO : Add test name');
my $style_doc = $parser.parse: :file('example/2.xsl');
my $stylesheet = $xslt.parse-stylesheet($style_doc);
my $results = $stylesheet.transform(:doc($source));
# TEST
is($stylesheet.media-type, 'text/html', ' TODO : Add test name');
# TEST
is($stylesheet.output-method, 'html', ' Test existence of output method');
$out2 = $results.Str-xslt;
# TEST
ok($out2, ' TODO : Add test name');
}

{
  my $style_doc = $parser.parse: :file('example/1.xsl');
  my $stylesheet = $xslt.parse-stylesheet($style_doc);
  my $results = $stylesheet.transform: :file('example/1.xml');
  my $out = $results.Str-xslt;
  # TEST
  ok ($out, ' TODO : Add test name' );
  # TEST
  is($out1, $out, ' TODO : Add test name' );
}

{
  my $style_doc = $parser.parse: :file('example/2.xsl');
  my $stylesheet = $xslt.parse-stylesheet($style_doc);
  my $results = $stylesheet.transform: :file('example/2.xml');
  my $out = $results.Str-xslt;
  # TEST
  ok( $out, ' TODO : Add test name' );
  # TEST
  is($out2, $out, ' TODO : Add test name' );
}

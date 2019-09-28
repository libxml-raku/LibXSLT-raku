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
my $style = $parser.parse: :file('example/1.xsl');
my $stylesheet = $xslt.parse-stylesheet(doc => $style);
my $results = $stylesheet.transform($source).Xslt;
$out1 = $results.Str;
# TEST
ok($out1, ' TODO : Add test name');
}

if v1.1.27 <= LibXSLT.version <= v1.1.29 {
    skip "tests broken on v1.1.27 <= LibXSLT <= v1.1.29", 4;
}
else {
    $source = $parser.parse: :file('example/2.xml');
    # TEST
    ok($source, ' TODO : Add test name');
    my $style = $parser.parse: :file('example/2.xsl');
    my $stylesheet = $xslt.parse-stylesheet(doc => $style);
    my $results = $stylesheet.transform($source).Xslt;
    # TEST
    is($stylesheet.media-type, 'text/html', ' TODO : Add test name');
    # TEST
    is($stylesheet.output-method, 'html', ' Test existence of output method');
    $out2 = $results.Str;
    # TEST
    ok($out2, ' TODO : Add test name');
}

{
  my $style = $parser.parse: :file('example/1.xsl');
  my $stylesheet = $xslt.parse-stylesheet(doc => $style);
  my $results = $stylesheet.transform(:file<example/1.xml>).Xslt;
  my $out = $results.Str;
  # TEST
  ok ($out, ' TODO : Add test name' );
  # TEST
  is($out1, $out, ' TODO : Add test name' );
}

if v1.1.27 <= LibXSLT.version <= v1.1.29 {
    skip "test broken on v1.1.27 <= LibXSLT <= v1.1.29", 2;
}
else {
  my $style = $parser.parse: :file('example/2.xsl');
  my $stylesheet = $xslt.parse-stylesheet(doc => $style);
  my $results = $stylesheet.transform(:file<example/2.xml>).Xslt;
  my $out = $results.Str;
  # TEST
  ok( $out, ' TODO : Add test name' );
  # TEST
  is($out2, $out, ' TODO : Add test name' );
}

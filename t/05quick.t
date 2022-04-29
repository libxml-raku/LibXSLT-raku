use v6;
use Test;
plan 8;
use LibXSLT;
use LibXSLT::Document;
use LibXSLT::Stylesheet;
use LibXML;
use LibXML::Document;

# this test is here because Mark Cox found a segfault
# that occurs when parse-stylesheet is immediately followed
# by a transform()

my LibXML:D $parser .= new;
my LibXSLT:D $xslt .= new;
my LibXML::Document:D $source = $parser.parse: :file('example/1.xml');

my ($out1, $out2);

{
my LibXML::Document:D $style = $parser.parse: :file('example/1.xsl');
my LibXSLT::Stylesheet:D $stylesheet = $xslt.parse-stylesheet(doc => $style);
my LibXSLT::Document::Xslt:D() $results = $stylesheet.transform($source);
$out1 = $results.Str;
ok($out1, ' TODO : Add test name');
}

if v1.1.27 <= LibXSLT.version <= v1.1.29 {
    skip "tests broken on v1.1.27 <= LibXSLT <= v1.1.29", 4;
}
else {
    $source = $parser.parse: :file('example/2.xml');
    my LibXML::Document:D $style = $parser.parse: :file('example/2.xsl');
    my LibXSLT::Stylesheet:D $stylesheet = $xslt.parse-stylesheet(doc => $style);
    my LibXSLT::Document::Xslt() $results = $stylesheet.transform($source);
    is $stylesheet.media-type, 'text/html', 'meda-type';
    is $stylesheet.output-method, 'html', ' Test existence of output method';
    $out2 = $results.Str;
    ok $out2;
}

{
  my LibXML::Document:D $style = $parser.parse: :file('example/1.xsl');
  my LibXSLT::Stylesheet:D $stylesheet = $xslt.parse-stylesheet(doc => $style);
  my LibXSLT::Document::Xslt:D() $results = $stylesheet.transform(:file<example/1.xml>);
  my $out = $results.Str;
  ok $out;
  is $out1, $out;
}

if v1.1.27 <= LibXSLT.version <= v1.1.29 {
    skip "test broken on v1.1.27 <= LibXSLT <= v1.1.29", 2;
}
else {
  my LibXML::Document:D $style = $parser.parse: :file('example/2.xsl');
  my LibXSLT::Stylesheet:D $stylesheet = $xslt.parse-stylesheet(doc => $style);
  my LibXSLT::Document::Xslt:D() $results = $stylesheet.transform(:file<example/2.xml>);
  my $out = $results.Str;
  ok $out;
  is $out2, $out;
}

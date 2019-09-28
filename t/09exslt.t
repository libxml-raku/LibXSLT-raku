use v6;
use Test;
plan 6;
use LibXSLT;
use LibXSLT::Native::Defs :BIND-XSLT;
use NativeCall;
use LibXML;
sub have-exslt(--> int32) is native(BIND-XSLT) is symbol('xslt6_config_have_exslt') {*};
##unless LibXSLT::Config.have-exslt {
unless have-exslt() {
    skip-rest "libexslt not supported in this libxml2 build";
    exit;
}

my $parser = LibXML.new();
# TEST
ok($parser, '$parser was initted.');

my $doc = $parser.parse: :string(q:to<EOT>);
<?xml version="1.0"?>

<doc>

</doc>
EOT

# TEST
ok($doc, '$doc is true.');

my $xslt = LibXSLT.new();
my $style_doc = $parser.parse: :string(q:to<EOT>);
<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:str="http://exslt.org/strings"
    exclude-result-prefixes="str">

<xsl:template match="/">
<out>;
 str:tokenize('2001-06-03T11:40:23', '-T:')
 <xsl:copy-of select="str:tokenize('2001-06-03T11:40:23', '-T:')"/>;
 str:tokenize('date math str')
 <xsl:copy-of select="str:tokenize('date math str')"/>;
</out>
</xsl:template>

</xsl:stylesheet>
EOT

# TEST

ok($style_doc, '$style_doc is true.');

# warn "Style_doc = \n", $style_doc.toString, "\n";

my $stylesheet = $xslt.parse-stylesheet(doc => $style_doc);

# TEST
ok($stylesheet, '$stylesheet is true.');

my $results = $stylesheet.transform(:$doc).Xslt;

# TEST
ok($results, '$results is true.');

my $output = $results.Str;

# TEST
ok($output, '$output is true.');

# warn "Results:\n", $output, "\n";

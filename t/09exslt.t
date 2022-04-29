use v6;
use Test;
plan 3;
use LibXSLT;
use LibXSLT::Config;
use LibXSLT::Document;
use LibXSLT::Raw::Defs :$BIND-XSLT;
use NativeCall;
use LibXML;
use LibXML::Document;
unless LibXSLT::Config.have-exslt {
    skip-rest "libexslt not supported in this libxml2 build";
    exit;
}

my LibXML:D $parser .= new();

my LibXML::Document:D $doc = $parser.parse: :string(q:to<EOT>);
<?xml version="1.0"?>

<doc>

</doc>
EOT

my LibXSLT:D $xslt .= new;
my LibXML::Document:D $style_doc = $parser.parse: :string(q:to<EOT>);
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

ok($style_doc, '$style_doc is true.');

# warn "Style_doc = \n", $style_doc.toString, "\n";

my $stylesheet = $xslt.parse-stylesheet(doc => $style_doc);

ok($stylesheet, '$stylesheet is true.');

my LibXSLT::Document::Xslt:D() $results = $stylesheet.transform(:$doc);

my $output = $results.Str;

ok $output, '$output is true.';

# warn "Results:\n", $output, "\n";

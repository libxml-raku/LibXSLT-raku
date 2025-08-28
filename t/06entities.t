use Test;
plan 2;
use LibXML;
use LibXSLT;
use LibXSLT::Document;
use LibXSLT::Stylesheet;

my LibXML:D $parser .= new;
my LibXSLT:D $xslt .= new;

$parser.expand-entities = True;

my LibXML::Document:D $source = $parser.parse: :string(qq{<?xml version="1.0" encoding="UTF-8"?>
<root>foo</root>});
my LibXML::Document:D $style = $parser.parse: :string( q:to<EOF> );
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE stylesheet [
<!ENTITY ouml   "&#246;">
]>

<xsl:stylesheet
     xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     version="1.0">
  <xsl:output method="xml" />

  <xsl:template match="/">
    <out>foo&ouml;bar</out>
   </xsl:template>

</xsl:stylesheet>
EOF


my LibXSLT::Stylesheet:D $stylesheet = $xslt.parse-stylesheet(doc => $style);

my LibXSLT::Document::Xslt() $results = $stylesheet.transform(doc => $source);

my $tostring = $results.Str;
like $tostring, /fooöbar/, '.Str matches entity.';

my $content = $results.Str;
like $content, /fooöbar/, 'xslt.Str matches entity.';


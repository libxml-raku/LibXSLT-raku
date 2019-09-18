use Test;
plan 2;
use LibXML;
use LibXSLT;

my $parser = LibXML.new();
my $xslt = LibXSLT.new();

# $parser.expand-entities = True;

my $source = $parser.parse: :string(qq{<?xml version="1.0" encoding="UTF-8"?>
<root>foo</root>});
my $style_doc = $parser.parse: :string('<?xml version="1.0" encoding="ISO-8859-1"?>
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
');


my $stylesheet = $xslt.parse-stylesheet($style_doc);

my $results = $stylesheet.transform(doc => $source);

my $tostring = $results.Str;
# TEST
like($tostring, /fooöbar/, '.Str matches entity.');

my $content = $results.Str-xslt;
like($content, /fooöbar/, '.Str-xslt matches entity.');


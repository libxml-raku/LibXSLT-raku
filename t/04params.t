use v6;
use Test;
plan 3;

use LibXSLT;
use LibXSLT::Document;
use LibXSLT::Stylesheet :&xpath-to-string;
use LibXML;

my LibXML:D $parser .= new;
my LibXSLT:D $xslt .= new;

my LibXML::Document:D $source = $parser.parse: :string(q:to<EOF>);
<?xml version="1.0" encoding="UTF-8" ?>
<top>
<next myid="next">NEXT</next>
<bottom myid="last">LAST</bottom>
</top>
EOF

my LibXML::Document:D $style = $parser.parse: :string(q:to<EOF>);
<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:output method="xml" indent="yes"/>
<xsl:param name="incoming"/>

<xsl:template match="*">
<xsl:value-of select="$incoming"/>
<xsl:text>&#xa;</xsl:text>
      <xsl:copy>
        <xsl:apply-templates select="*"/>
        </xsl:copy>
</xsl:template>

</xsl:stylesheet>
EOF

my LibXSLT::Stylesheet:D $stylesheet = $xslt.parse-stylesheet(doc => $style);

my LibXSLT::Document::Xslt:D() $results = $stylesheet.transform(:doc($source),
        incoming => 'INCOMINGTEXT',
        outgoing => 'OUTGOINGTEXT',
        );

ok $results.Str;

my %params =  xpath-to-string(str => 'TEXT', num => 42, bool => True, empty => Mu);
is-deeply %params, %(str => "'TEXT'", num => '42', bool => 'true()', empty => "''");
%params = xpath-to-string(empty => Mu);
$results = $stylesheet.transform(:doc($source), :raw, |%params);

ok $results.Str;


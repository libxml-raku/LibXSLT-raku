use v6;
use Test;
plan 7;

use LibXSLT;
use LibXSLT::Stylesheet :&xpath-to-string;
use LibXML;

my $parser = LibXML.new();
my $xslt = LibXSLT.new();

my $source = $parser.parse: :string(q:to<EOF>);
<?xml version="1.0" encoding="UTF-8" ?>
<top>
<next myid="next">NEXT</next>
<bottom myid="last">LAST</bottom>
</top>
EOF

# TEST

ok($source, ' TODO : Add test name');

my $style = $parser.parse: :string(q:to<EOF>);
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

# TEST
ok($style, ' TODO : Add test name');

my $stylesheet = $xslt.parse-stylesheet(doc => $style);

# TEST
ok($stylesheet, ' TODO : Add test name');

my $results = $stylesheet.transform(:doc($source),
        incoming => 'INCOMINGTEXT',
        outgoing => 'OUTGOINGTEXT',
        ).Xslt;

# TEST
ok($results, ' TODO : Add test name');

# TEST
ok($results.Str, ' TODO : Add test name');

my %params = xpath-to-string(empty => Mu);
$results = $stylesheet.transform(:doc($source), :raw, |%params).Xslt;
# TEST
ok($results, ' TODO : Add test name');
# TEST
ok($results.Str, ' TODO : Add test name');


use v6;
use Test;
plan 6;

use LibXSLT;
use LibXML;

my LibXML $parser .= new();
# TEST

ok($parser, ' TODO : Add test name');

my $doc = $parser.parse: :string(q:to<EOT>);
<?xml version="1.0"?>
  <dromedaries>
    <species name="Camel">
      <humps>1 or 2</humps>
      <disposition>Cranky</disposition>
    </species>
    <species name="Llama">
      <humps>1 (sort of)</humps>
      <disposition>Aloof</disposition>
    </species>
    <species name="Alpaca">
      <humps>(see Llama)</humps>
      <disposition>Friendly</disposition>
    </species>
</dromedaries>
EOT

# TEST

ok($doc, ' TODO : Add test name');

my LibXSLT $xslt .= new();
my $style_doc = $parser.parse: :string(q:to<EOT>);
<xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:template match="/">
  <html>
  <head><title>Know Your Dromedaries</title></head>
  <body>
    <table bgcolor="#eeeeee" border="1">
    <tr>
    <th>Species</th>
    <th>No of Humps</th>
    <th>Disposition</th>
    </tr>
    <xsl:for-each select="dromedaries">
      <xsl:apply-templates select="./species" />
    </xsl:for-each>
  </table>
  </body>
  </html>
</xsl:template>

<xsl:template match="species">
  <tr>
  <td><xsl:value-of select="@name" /></td>
  <td><xsl:value-of select="humps" /></td>
  <td><xsl:value-of select="disposition" /></td>
  </tr>
</xsl:template>

</xsl:stylesheet>
EOT

# TEST
ok($style_doc.defined, ' TODO : Add test name');

# warn "Style_doc = \n", $style_doc->toString, "\n";

warn;
my $stylesheet = $xslt.parse-stylesheet(doc => $style_doc);
warn;

# TEST
ok($stylesheet.defined && $stylesheet.native.defined, ' TODO : Add test name');

my $results = $stylesheet.transform(:$doc);

# TEST
ok($results, ' TODO : Add test name');

skip('todo: output-string');
##my $output = $stylesheet.output-string($results);

# TEST
##ok($output, ' TODO : Add test name');

# warn "Results:\n", $output, "\n";

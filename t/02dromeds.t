use v6;
use Test;
plan 1;

use LibXSLT;
use LibXSLT::Document;
use LibXML;
use LibXML::Document;

my LibXML:D $parser .= new();

my LibXML::Document:D $doc = $parser.parse: :string(q:to<EOT>);
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

my LibXSLT:D $xslt .= new();
my LibXML::Document:D $style_doc = $parser.parse: :string(q:to<EOT>);
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

my LibXSLT::Stylesheet:D $stylesheet = $xslt.parse-stylesheet(doc => $style_doc);
my LibXSLT::Document::Xslt:D() $results = $stylesheet.transform(:$doc);

ok $results.Str;


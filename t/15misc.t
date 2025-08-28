use v6;
use Test;
plan 3;
use LibXML;
use LibXML::Document;
use LibXSLT;
use LibXSLT::Stylesheet;
use LibXSLT::Document;

{
  # test for Perl #41542 - DTD subset disappeared
  # in the source document after the transformation
  my LibXML:D $parser .= new();
  $parser.validation = True;
  $parser.expand_entities = False;
  my $xml = q:to<EOT>;
    <?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <!DOCTYPE article [
    <!ENTITY foo "FOO">
    <!ELEMENT article (#PCDATA)>
    ]>
    <article>&foo;</article>
    EOT

  my LibXML::Document:D $doc = $parser.parse: :string($xml);

  my LibXSLT:D $xslt .= new();
  $parser.validation = False;
  my LibXML::Document:D $style_doc = $parser.parse: :string(q:to<EOX>);
    <?xml version="1.0" encoding="utf-8"?>
    <xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:template match="/">
    <out>hello</out>
    </xsl:template>
    </xsl:transform>
    EOX

  is $doc.Str, $xml, '.Str() No. 1';
  $xslt.parse-stylesheet($style_doc).transform($doc);
  is $doc.Str(), $xml, 'Str() No. 2';

}

{
  # test work-around for Perl rt #29572

  my LibXML:D $parser .= new();
  my LibXML::Document:D $source = $parser.parse: :string(q:to<EOT>);
  <some-xml/>
  EOT
  my LibXML::Document:D $style_doc = $parser.load(string=>q:to<EOT2>, :!cdata);
    <xsl:stylesheet version="1.0"
          xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

      <xsl:template match="/" >
        <xsl:text
          disable-output-escaping="yes"><![CDATA[<tr>]]></xsl:text>
      </xsl:template>

    </xsl:stylesheet>
    EOT2
  my LibXSLT:D $xslt .= new();
  my LibXSLT::Stylesheet:D $stylesheet = $xslt.parse-stylesheet($style_doc);

  my LibXSLT::Document::Xslt:D() $results = $stylesheet.transform($source);
  my $out = $results.Str;
  is $out, q:to<EOF>, '$out is equal to <tr>';
    <?xml version="1.0"?>
    <tr>
    EOF

}

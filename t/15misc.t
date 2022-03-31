use v6;
use Test;
plan 4;
use LibXML;
use LibXSLT;

{
  # test for #41542 - DTD subset disappeare
  # in the source document after the transformation
  my $parser = LibXML.new();
  $parser.validation(1);
  $parser.expand_entities(0);
  my $xml = q:to<EOT>;
    <?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <!DOCTYPE article [
    <!ENTITY foo "FOO">
    <!ELEMENT article (#PCDATA)>
    ]>
    <article>&foo;</article>
    EOT

  my $doc = $parser.parse: :string($xml);

  my $xslt = LibXSLT.new();
  $parser.validation(0);
  my $style_doc = $parser.parse: :string(q:to<EOX>);
    <?xml version="1.0" encoding="utf-8"?>
    <xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:template match="/">
    <out>hello</out>
    </xsl:template>
    </xsl:transform>
    EOX

  # TEST
  is($doc.Str, $xml, '.Str() No. 1');
  $xslt.parse-stylesheet($style_doc).transform($doc);
  # TEST
  is($doc.Str(), $xml, 'Str() No. 2');

}

{
  # test work-around for rt #29572

  my $parser = LibXML.new();
  my $source = $parser.parse: :string(q:to<EOT>);
    <some-xml/>
    EOT
  my $style_doc = $parser.load(string=>q:to<EOT2>, :!cdata);
    <xsl:stylesheet version="1.0"
          xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

      <xsl:template match="/" >
        <xsl:text
          disable-output-escaping="yes"><![CDATA[<tr>]]></xsl:text>
      </xsl:template>

    </xsl:stylesheet>
    EOT2
  my $xslt = LibXSLT.new();
  my $stylesheet = $xslt.parse-stylesheet($style_doc);

  my $results = $stylesheet.transform($source).Xslt;
  # TEST
  ok($results, ' TODO : Add test name');
  my $out = $results.Str;
  # TEST
  is($out, q:to<EOF>, '$out is equal to <tr>');
    <?xml version="1.0"?>
    <tr>
    EOF

}

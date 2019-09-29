use v6;
use Test;

plan 2;

subtest 'LibXSLT Synopsis' => {
  plan 1;
  use LibXSLT;
  use LibXML::Document;

  my LibXML::Document $xml .= parse(location => 'example/1.xml');
  my LibXML::Document $xsl .= parse(location=>'example/1.xsl', :!cdata);

  my Str $result = LibXSLT.process: :$xml, :$xsl;

  # OO interface
  use LibXSLT::Document;
  use LibXSLT::Stylesheet;
  my LibXSLT $xslt .= new();

  my LibXSLT::Stylesheet $stylesheet = $xslt.parse-stylesheet($xsl);
  my LibXSLT::Document::Xslt $results = $stylesheet.transform($xml).Xslt;
  ok $results.Str;
}

subtest 'LibXSLT Synopsis' => {
  plan 6;
  use LibXSLT;
  ok LibXSLT.max-depth, 'get default max-depth';
  lives-ok { LibXSLT.max-depth = 42}, 'set max-depth';
  is LibXSLT.max-depth, 42, 'get max-depth';
  ok LibXSLT.max-vars, 'get default max-vars';
  lives-ok { LibXSLT.max-vars = 99}, 'set max-vars';
  is LibXSLT.max-vars, 99, 'get max-depth';
}


done-testing;
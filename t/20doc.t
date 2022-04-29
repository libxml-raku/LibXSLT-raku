use v6;
use Test;

plan 4;

subtest 'LibXSLT Synopsis' => {
  plan 1;
  use LibXSLT;
  use LibXML::Document;

  my LibXML::Document:D $doc .= parse(location => 'example/1.xml');
  my LibXML::Document:D $xsl .= parse(location => 'example/1.xsl', :!cdata);

  my Str $result = LibXSLT.process: :$doc, :$xsl;

  # OO interface
  use LibXSLT::Document;
  use LibXSLT::Stylesheet;
  my LibXSLT:D $xslt .= new();

  my LibXSLT::Stylesheet:D $stylesheet = $xslt.parse-stylesheet($xsl);
  my LibXSLT::Document::Xslt() $results = $stylesheet.transform(:$doc);
  ok $results.Str;
}

subtest 'LibXSLT Options' => {
  plan 6;
  use LibXSLT;
  ok LibXSLT.max-depth, 'get default max-depth';
  lives-ok { LibXSLT.max-depth = 42}, 'set max-depth';
  is LibXSLT.max-depth, 42, 'get max-depth';
  ok LibXSLT.max-vars, 'get default max-vars';
  lives-ok { LibXSLT.max-vars = 99}, 'set max-vars';
  is LibXSLT.max-vars, 99, 'get max-vars';
}

subtest 'LibXSLT Parse' => {
    plan 1;
    use LibXSLT::Stylesheet;
    use LibXML::Document ;
    my LibXML::Document:D $stylesheet-doc .= parse(location=>"example/1.xsl", :!cdata);
    my LibXSLT::Stylesheet:D $stylesheet .= parse-stylesheet($stylesheet-doc);
    pass;
}

subtest 'LibXSLT Transform' => {
    plan 1;
    use LibXSLT::Stylesheet;
    use LibXML::Document ;
    my LibXML::Document:D $stylesheet-doc .= parse(location=>"example/1.xsl", :!cdata);
    my LibXSLT::Stylesheet:D $stylesheet .= parse-stylesheet($stylesheet-doc);
    pass;
}

done-testing;

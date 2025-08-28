use v6;
use Test;
plan 6;

use LibXSLT;
use LibXSLT::Stylesheet;
use LibXML;
use LibXML::Document;

use LibXML::XPath::Context;
LibXML::XPath::Context.SetGenericErrorFunc(sub (|c) {});

my $bad_xsl1 = 'example/bad1.xsl';
my $bad_xsl2 = 'example/bad2.xsl';
my $bad_xsl3 = 'example/bad3.xsl';
my $fatal_xsl = 'example/fatal.xsl';
my $nonfatal_xsl = 'example/nonfatal.xsl';
my $good_xsl = 'example/1.xsl';
my $good_xml = 'example/1.xml';
my $bad_xml  = 'example/bad2.xsl';

my LibXSLT:D $xslt .= new;

subtest 'parse stylesheet error', {
    my LibXML::Document:D $stylesheet = LibXML.parse: :file($bad_xsl1);
    dies-ok { $xslt.parse-stylesheet($stylesheet) };

    throws-like { LibXML.parse: :file($bad_xsl2) }, X::LibXML::Parser;
}

subtest 'parse stylesheet success', {
    my LibXML::Document:D $stylesheet = LibXML.parse: :file($good_xsl);
    my LibXSLT:D $parsed = $xslt.parse-stylesheet( $stylesheet );
    throws-like { $parsed.transform: :file( $bad_xml ); }, X::LibXML::Parser;
}

subtest 'transform error', {
  my LibXML::Document:D $stylesheet = LibXML.new.parse: :file($nonfatal_xsl);
  my LibXSLT::Stylesheet:D $parsed = $xslt.parse-stylesheet( $stylesheet );
  throws-like { $parsed.transform: :file( $good_xml ); }, X::LibXML::Parser, :message(/'Non-fatal message.'/);
}

subtest 'document transform error', {
  my LibXML $parser .= new;
  my LibXML::Document:D $stylesheet = $parser.parse: :file($bad_xsl3);
  my LibXSLT::Stylesheet:D $parsed = $xslt.parse-stylesheet( $stylesheet );
  throws-like { $parsed.transform :file( $good_xml ); }, X::LibXML::Parser;
  my LibXML::Document:D $dom = $parser.parse: :file( $good_xml );
  throws-like { $parsed.transform( $dom ); }, X::LibXML::Parser;
}

subtest 'document transform fatal', {
  my LibXML $parser .= new;
  my LibXML::Document:D $stylesheet = $parser.parse: :file($fatal_xsl);
  my LibXSLT::Stylesheet:D $parsed = $xslt.parse-stylesheet( $stylesheet );
  throws-like { $parsed.transform: :file( $good_xml ); }, X::LibXML::Parser;
  my LibXML::Document:D $dom = $parser.parse: :file( $good_xml );
  throws-like { $parsed.transform( $dom ); }, X::LibXML::Parser;
}

subtest 'transform variable error', {
    my LibXML:D $parser .= new;
    my LibXML::Document:D $doc = $parser.parse: :string(q:to<XML>);
    <doc/>
    XML

    my LibXSLT:D $xslt .= new;
    my LibXML::Document:D $style_doc = $parser.parse: :string(q:to<XSLT>);
    <xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:template match="/">
        <xsl:value-of select="$foo"/>
      </xsl:template>
    </xsl:stylesheet>
    XSLT

    $xslt .= parse-stylesheet($style_doc);

    throws-like { $xslt.transform($doc); }, X::LibXML::Parser, :message(rx:i/'unregistered variable foo'|"variable 'foo' has not been declared"/);
}

use v6;
use Test;
plan 9;

use LibXML;
use LibXML::Document;
use LibXML::Node::List;
use LibXSLT;
use LibXSLT::Document;

use LibXSLT::Raw::Defs :$BIND-XSLT;
use NativeCall;
sub have-exslt(--> int32) is native($BIND-XSLT) is symbol('xslt6_config_have_exslt') {*};

subtest 'medley', {
    my LibXML:D $parser .= new();
    my LibXSLT:D $xslt .= new();

    $xslt.register-function('urn:foo', 'test', sub ($v1, $v2?) {
            pass 'urn:foo was reached.';
            return $v1.Str ~ ($v2 // '');
        }
    );
    $xslt.register-function('urn:foo', 'test2', sub ($v1) {
            isa-ok $v1, 'LibXML::Node::Set', 'First argument is a Node Set';
            $v1.WHAT.raku;
        }
    );
    $xslt.register-function('urn:foo', 'test3', sub (*@a) {
            is +@a, 0, 'No arguments were received.';
            return;
        }
    );

    my LibXML::Document:D $source = $parser.parse: :string(q:to<EOT>);
    <?xml version="1.0" encoding="ISO-8859-1"?>
    <document></document>
    EOT

    my LibXML::Document:D $style = $parser.parse: :string(q:to<EOT>);
    <xsl:stylesheet
        version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:foo="urn:foo"
    >
    <xsl:variable name="FOO"><xsl:call-template name="Foo"/></xsl:variable>
    <xsl:template name="Foo"/>

    <xsl:template match="/">
      (( <xsl:value-of select="foo:test('Foo', '!')"/> ))
      (( <xsl:value-of select="foo:test('Foo', '!')"/> ))
           <!-- this works -->
         <xsl:value-of select="foo:test(string($FOO))"/>
           <!-- this only works in 1.52 -->
         <xsl:value-of select="foo:test($FOO)"/>
      [[ <xsl:value-of select="foo:test2(/*)"/> ]]
      [[ <xsl:value-of select="foo:test2(/*)"/> ]]
      (( <xsl:value-of select="foo:test3()"/> ))
      (( <xsl:value-of select="foo:test3()"/> ))
    </xsl:template>

    </xsl:stylesheet>
    EOT

    my LibXSLT::Stylesheet:D $stylesheet = $xslt.parse-stylesheet(doc => $style);
    my LibXSLT::Document::Xslt:D() $results = $stylesheet.transform(doc => $source);
    like $results.Str, /'Foo!'/, 'Matches Foo!';
    like $results.Str, /'Node::Set'/, 'Matches Node::Set';

    $xslt.register-function('urn:foo', 'get_list', &get_nodelist );

    our @words = <one two three>;

    sub get_nodelist {
        my LibXML::Node::Set $nl .= new();
        $nl.push(LibXML::Text.new($_)) for @words;
        return $nl;
    }

    $style = $parser.parse: :string(q:to<EOT>);
    <xsl:stylesheet version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:foo="urn:foo">

      <xsl:template match="/">
          <xsl:for-each select='foo:get_list()'>
            <li><xsl:value-of select='.'/></li>
          </xsl:for-each>
      </xsl:template>

    </xsl:stylesheet>
    EOT

    ok $style, '$style init - 2';

    $stylesheet = $xslt.parse-stylesheet(doc => $style);
    for 1..5 -> $n {
        $results = $stylesheet.transform(doc => $source);

        like($results.Str,
             /'<li>one</li>'/,
             'Matches li-one - ' ~ $n
            );
        like(
            $results.Str,
            /'<li>one</li><li>two</li><li>three</li>'/,
            'Output matches multiple lis - ' ~ $n
        );
    }
}

{
    # Perl testcases by Elizabeth Mattijsen
    my LibXML:D $parser .= new;
    my LibXSLT:D $xsltproc .= new;

    my LibXML::Document:D $xml  = $parser.parse: :string( q:to<XML> );
    <html><head/></html>
    XML
    my LibXML::Document:D $xslt = $parser.parse: :string( q:to<XSLT> );
    <xsl:stylesheet
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns:foo="http://foo"
      version="1.0">
    <xsl:template match="/html">
       <html>
         <xsl:apply-templates/>
       </html>
    </xsl:template>
    <xsl:template match="/html/head">
      <head>
       <xsl:copy-of select="foo:custom()/foo"/>
       <xsl:apply-templates/>
      </head>
    </xsl:template>
    </xsl:stylesheet>
    XSLT

    my $aux = q:to<XML>;
    <bar>
      <y><foo>1st</foo></y>
      <y><foo>2nd</foo></y>
    </bar>
    XML

    subtest 'custom function returning node-set', {
        LibXSLT.register-function(
            'http://foo', 'custom', sub { $parser.parse(:string( $aux )).findnodes('//y') }
        );
        my LibXSLT::Stylesheet:D $stylesheet = $xsltproc.parse-stylesheet(doc => $xslt);
        my LibXSLT::Document::Xslt:D() $result = $stylesheet.transform(doc => $xml);
        # the behavior has changed in some version of libxslt
        my $expect = qq{'<html xmlns:foo="http://foo">'<head><foo>1st</foo><foo>2nd</foo></head></html>\n};
        like($result.serialize,
             /'<html xmlns:foo="http://foo"><head>' .* '<foo>1st</foo><foo>2nd</foo>' .* '</head></html>'/,
             'Results serialize matches text.'
            );
    }

    subtest 'custom function returning single node', {
        LibXSLT.register-function(
            'http://foo', 'custom', sub { $parser.parse(:string( $aux )).findnodes('//y').[0]; });
        my LibXSLT::Stylesheet:D $stylesheet = $xsltproc.parse-stylesheet($xslt);
        my LibXSLT::Document::Xslt:D() $result = $stylesheet.transform($xml);
        my $expect = qq{<html xmlns:foo="http://foo"><head><foo>1st</foo></head></html>\n};
        like(
            $result.serialize,
            /'<html xmlns:foo="http://foo"><head>' .* '<foo>1st</foo>' .* '</head></html>'/,
            'Results serialize matches text - 2.'
        );
    }
}

subtest 'xpath expression on input node', {
    my LibXML:D $parser  .= new;
    my LibXSLT:D $xsltproc .= new;
    my $xslt = $parser.parse: :string( q:to<XSLT> );
    <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns:x="http://x/x"
      version="1.0">
    <xsl:namespace-alias stylesheet-prefix="x" result-prefix="#default"/>
    <xsl:template match="/">
       <out>
         <xsl:copy-of select="x:test(.)"/>
       </out>
    </xsl:template>
    </xsl:stylesheet>
    XSLT
    $xsltproc.register-function(
        "http://x/x", 'test', sub ($nodes) { $nodes[0].findnodes('//b[parent::a]') }
    );
    my LibXSLT::Stylesheet:D $stylesheet = $xsltproc.parse-stylesheet($xslt);
    my LibXSLT::Document::Xslt:D() $result = $stylesheet.transform($parser.parse: :string( q:to<XML> ));
    <a><b><b/></b><b><c/></b></a>
    XML
    is $result.serialize,
       qq{<?xml version="1.0"?>\n<out><b><b/></b><b><c/></b></out>\n},
       'result is right.';
}

subtest 'echoing and dereferencing functions', {
    my $callbackNS = "http://x/x";

    my LibXML:D $p .= new;
    my LibXSLT:D $xsltproc .= new;
    $xsltproc.register-function(
        $callbackNS,
        "some_function",
        sub ($format) {
            return $format;
        }
    );
    $xsltproc.register-function(
        $callbackNS,
        "some_function2",
        sub ($format) {
            return $format.[0];
        }
    );

    my LibXML::Document:D $xsltdoc = $p.parse: :string(q:to<EOF>);
    <?xml version="1.0" encoding="utf-8"?>
    <xsl:stylesheet version="1.0"
         xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
         xmlns:x="http://x/x"
    >

    <xsl:template match="root">
      <root>
        <xsl:value-of select="x:some_function(@format)" />
        <xsl:text>,</xsl:text>
        <xsl:value-of select="x:some_function(.)" />
        <xsl:text>,</xsl:text>
        <xsl:value-of select="x:some_function(processing-instruction())" />
        <xsl:text>,</xsl:text>
        <xsl:value-of select="x:some_function(text())" />
        <xsl:text>;</xsl:text>

        <xsl:value-of select="x:some_function2(@format)" />
        <xsl:text>,</xsl:text>
        <xsl:value-of select="x:some_function2(.)" />
        <xsl:text>,</xsl:text>
        <xsl:value-of select="x:some_function2(processing-instruction())" />
        <xsl:text>,</xsl:text>
        <xsl:value-of select="x:some_function2(text())" />
        <xsl:text>;</xsl:text>
        <xsl:for-each select="x:some_function(node())">
          <xsl:value-of select="." />
        </xsl:for-each>
      </root>
    </xsl:template>

    </xsl:stylesheet>
    EOF

    my LibXML::Document $doc = $p.parse: :string(q:to<EOF>);
    <root format="foo">bar<?baz bak?><y>zzz</y></root>
    EOF

    my LibXSLT::Stylesheet:D $stylesheet = $xsltproc.parse-stylesheet($xsltdoc);
    my LibXSLT::Document::Xslt:D() $result = $stylesheet.transform($doc);
    my $val = $result.findvalue("/root");
    ok $val.defined, 'val is defined.';

    is($val, "foo,barzzz,bak,bar;foo,barzzz,bak,bar;barbakzzz",
       'val has the right value.')
        or print $result.Str;

}

subtest 'value-of function', {
    my $NS = "http://foo";

    my LibXML:D $p .= new;
    my LibXSLT:D $xsltproc .= new;

    my LibXML::Document:D $xsltdoc = $p.parse: :string(qq:to<EOF>);
    <?xml version="1.0" encoding="utf-8"?>
    <xsl:stylesheet version="1.0"
         xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
         xmlns:foo="$NS"
    >

    <xsl:template match="root">
    <root>
    <xsl:value-of select="foo:bar(10)" />
    </root>
    </xsl:template>

    </xsl:stylesheet>
    EOF

    my LibXML::Document $doc = $p.parse: :string(q:to<EOF>);
    <root></root>
    EOF

    my LibXSLT::Stylesheet $stylesheet = $xsltproc.parse-stylesheet($xsltdoc);
    $stylesheet.register-function($NS, "bar", sub ($_) { return $_ * 2 });
    my LibXSLT::Document::Xslt() $result = $stylesheet.transform($doc);
    my $val = $result.findvalue("/root");
    is($val, 20, "contextual register_function" );
}

subtest 'extension-element-prefixes', {
    my $NS = "http://foo";

    my LibXML:D $p .= new;
    my LibXSLT:D $xsltproc .= new;

    my LibXML::Document:D $xsltdoc = $p.parse: :string(qq:to<EOF>);
    <?xml version="1.0" encoding="utf-8"?>
    <xsl:stylesheet version="1.0"
         xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
         xmlns:foo="$NS"
             extension-element-prefixes="foo"
    >

    <xsl:template match="root">
    <root>
    <foo:bar value="10"/>
    </root>
    </xsl:template>

    </xsl:stylesheet>
    EOF

    my LibXML::Document:D $doc = $p.parse: :string(q:to<EOF>);
    <root></root>
    EOF

    my LibXSLT::Stylesheet:D $stylesheet = $xsltproc.parse-stylesheet($xsltdoc);
    $stylesheet.register-transform('element', $NS, "bar", sub ($ctx) {
        my LibXML::Node:D $style = $ctx.style-node;
        my LibXML::Node:D $insert = $ctx.insert-node;
        $insert.addChild: LibXML::Text.new( $style<@value> );
    });
    my LibXSLT::Document::Xslt:D() $result = $stylesheet.transform($doc);
    my $val = $result.findvalue("/root");
    is($val, 10, "contextual register_element");
}


if have-exslt() {
    subtest 'GNOME Bugzilla bug #562302', {
        my LibXML:D $parser .= new;
        my LibXSLT:D $xslt .= new;

        # registering function
        LibXSLT.register-function("urn:perl", 'cfg', sub {
            return $parser.parse: :string('<xml_storage/>');
        });

        # loading and parsing stylesheet
        my LibXML::Document:D $style_doc = $parser.parse: :string(q:to<EOF>);
        <xsl:stylesheet version="1.0"
            xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
            xmlns:exslt="http://exslt.org/common"
            xmlns:perl="urn:perl"
            exclude-result-prefixes="exslt perl">

        <xsl:variable name="xml_storage" select="perl:cfg()/xml_storage" />

        <xsl:variable name="page-data-tree">
            <title><xsl:value-of select="$xml_storage"/></title>
            <crumbs>
                <page><url>hello</url></page>
                <page><url>bye</url></page>
            </crumbs>
        </xsl:variable>
        <xsl:variable name="page-data" select="exslt:node-set($page-data-tree)" />

        <xsl:template match="/">
            <result><xsl:copy-of select="$xml_storage"/></result>
        </xsl:template>

        </xsl:stylesheet>
        EOF

        my LibXSLT::Stylesheet:D $stylesheet = $xslt.parse-stylesheet($style_doc);

        # performing transform
        my LibXML::Document:D $source .= new;
        my LibXSLT::Document::Xslt:D() $results = $stylesheet.transform($source);

        my $string = $results.Str;
        my $expected = q:to<EOF>;
        <?xml version="1.0"?>
        <result><xml_storage/></result>
        EOF

        is $string, $expected, 'GNOME Bugzilla bug #562302';
    }
}
else {
    skip "test requires libexslt";
}

END pass 'Reached here.';


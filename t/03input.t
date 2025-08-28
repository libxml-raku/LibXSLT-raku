use v6;
use Test;
plan 14;
use LibXML;
use LibXML::Document;
use LibXML::InputCallback;
use LibXSLT;
use LibXSLT::Document;
use LibXSLT::Stylesheet;

my LibXML:D $parser .= new();

my LibXML::Document:D $doc = $parser.parse: :string(q:to<EOT>);
<xml>random contents</xml>
EOT

my LibXSLT:D $xslt .= new;

my $stylsheetstring = q:to<EOT>;
<xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns="http://www.w3.org/1999/xhtml">

<xsl:template match="/">
<html>
<head><title>Know Your Dromedaries</title></head>
<body>
  <h1><xsl:apply-templates/></h1>
  <p>foo: <xsl:apply-templates select="document('foo.xml')/*" /></p>
</body>
</html>
</xsl:template>

</xsl:stylesheet>
EOT

my LibXML::InputCallback:D $icb .= new();

$icb.register-callbacks: [ &match-cb, &open-cb,
                            &read-cb, &close-cb ];

$xslt.input-callbacks($icb);

my LibXSLT::Stylesheet:D $stylesheet = $xslt.parse-stylesheet: doc => $parser.parse: :string($stylsheetstring);
# stylesheet

my LibXSLT::Document:D $results = $stylesheet.transform: :$doc;
my $output = $results.Str;
ok $output, 'output is OK.';

# test a dying close callback
# callbacks can only be registered as a callback group
$icb .= new;
$icb.register-callbacks( &match-cb, &dying-open-cb, &read-cb, &close-cb );
$xslt.input-callbacks($icb);
$stylesheet = $xslt.parse-stylesheet: doc => $parser.parse: :string($stylsheetstring);

try {
    $stylesheet.transform: :$doc;
}
$!.&isa-ok: X::LibXML::AdHoc, "Threw $!";

#
# test callbacks for parse_stylesheet()
#

$xslt .= new;
$icb .= new;

$icb.register-callbacks: [ &match-cb, &stylesheet-open-cb,
                           &read-cb, &close-cb ];

$xslt.input-callbacks($icb);

$stylsheetstring = q:to<EOT>;
<xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns="http://www.w3.org/1999/xhtml">

<xsl:import href="foo.xml"/>

<xsl:template match="/">
<html>
<head><title>Know Your Dromedaries</title></head>
<body>
  <h1><xsl:apply-templates/></h1>
  <p>Dahut!</p>
</body>
</html>
</xsl:template>

</xsl:stylesheet>
EOT

$stylesheet = $xslt.parse-stylesheet: doc => $parser.parse: :string($stylsheetstring);
# stylesheet
ok($stylesheet, 'stylesheet is OK - 2.');

#
# Test not matching callback
# This also verifies that all the previous callbacks were unregistered.
#

$xslt .= new;
$icb .= new;

$icb.register-callbacks: [ &match-cb, &stylesheet-open-cb,
                            &read-cb, &close-cb ] ;

$xslt.input-callbacks($icb);

my $no-match-count = 0;

$stylsheetstring = q:to<EOT>;;
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/">
        <result>
            <xsl:apply-templates select="document('not-found.xml')/*"/>
        </result>
    </xsl:template>
</xsl:stylesheet>
EOT

$stylesheet = $xslt.parse-stylesheet: doc => $parser.parse: :string($stylsheetstring);
# stylesheet
ok($stylesheet, 'stylesheet is OK - 3.');

$stylesheet.suppress-warnings = True;
$results = $stylesheet.transform: :$doc;
ok $results.Str, 'results is OK - 3.';

is $no-match-count, 1, 'match-cb called once if no match';

#
# input callback functions
#

multi match-cb('foo.xml') {
    pass('URI is OK in match-cb.');
    True;
}
multi match-cb('not-found.xml') {
    ++$no-match-count;
    False
}
multi match-cb($) { False }

sub open-cb($uri) {
    $uri.&is: 'foo.xml', 'URI is OK in open-cb.';
    my $str ="<foo>Text here</foo>";
    return $str.encode;
}

sub dying-open-cb($uri) {
    is $uri, 'foo.xml', 'dying-open-cb';
    die "Test a die from open-cb";
}

sub stylesheet-open-cb($uri) {
    is $uri, 'foo.xml', 'stylesheet-open-cb uri compare.';
    my $str = '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"/>';
    return $str.encode;
}

sub close-cb($) {
    pass 'close-cb()';
}

sub read-cb($buf is rw, $n) {
    my $rv = $buf.subbuf(0, $n);
    $buf .= subbuf(min($n, $buf.elems));
    return $rv;
}

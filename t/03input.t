use v6;
use Test;
plan 15;
use LibXML;
use LibXML::Document;
use LibXML::InputCallback;
use LibXSLT;
use LibXSLT::Document;
use LibXSLT::Stylesheet;


my LibXML:D $parser .= new();
# parser
ok($parser, 'Parser was initted.');

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

# registering callbacks
$icb.register-callbacks( [ &match_cb, &open_cb,
                            &read_cb, &close_cb ] );

$xslt.input-callbacks($icb);

my LibXSLT::Stylesheet:D $stylesheet = $xslt.parse-stylesheet: doc => $parser.parse: :string($stylsheetstring);
# stylesheet

#$stylesheet.input-callbacks($icb);

# warn "transforming\n";
my LibXSLT::Document:D $results = $stylesheet.transform: :$doc;
my $output = $results.Str;
# warn "output: $output\n";
ok $output, 'output is OK.';

# test a dying close callback
# callbacks can only be registered as a callback group
$icb .= new;
$icb.register-callbacks( &match_cb, &dying_open_cb, &read_cb, &close_cb );
$xslt.input-callbacks($icb);
$stylesheet = $xslt.parse-stylesheet: doc => $parser.parse: :string($stylsheetstring);
# check if transform throws an exception
# dying callback test
try {
    $stylesheet.transform: :$doc;
    $*XML-CONTEXT.flush-errors;
};

{
    my $E = $!;
    ok $E.defined, "Threw: $E";
}

#
# test callbacks for parse_stylesheet()
#

$xslt .= new;
$icb .= new;

# registering callbacks
$icb.register-callbacks( [ &match_cb, &stylesheet_open_cb,
                            &read_cb, &close_cb ] );

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

# registering callbacks
$icb.register-callbacks( [ &match_cb, &stylesheet_open_cb,
                            &read_cb, &close_cb ] );

$xslt.input-callbacks($icb);

my $no_match_count = 0;

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
# results
ok $results.Str, 'results is OK - 3.';

# no_match_count
is $no_match_count, 1, 'match_cb called once if no match';

#
# input callback functions
#

sub match_cb($uri) {
    # match_cb
    if ($uri eq "foo.xml") {
        ok(1, 'URI is OK in match_cb.');
        return 1;
    }
    if ($uri eq "not-found.xml") {
        ++$no_match_count;
        return 0;
    }
    return 0;
}

sub open_cb($uri) {
    is($uri, 'foo.xml', 'URI is OK in open_cb.');
    my $str ="<foo>Text here</foo>";
    return $str.encode;
}

sub dying_open_cb($uri) {
    # dying_open_cb: $uri
    is $uri, 'foo.xml', 'dying_open_cb';
    die "Test a die from open_cb";
}

sub stylesheet_open_cb($uri) {
    is $uri, 'foo.xml', 'stylesheet_open_cb uri compare.';
    my $str = '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"/>';
    return $str.encode;
}

sub close_cb($) {
    # warn("close\n");
    pass 'close_cb()';
}

sub read_cb($buf is rw, $n) {
    #    warn("read\n");
    my $rv = $buf.subbuf(0, $n);
    $buf .= subbuf(min($n, $buf.elems));
    return $rv;
}

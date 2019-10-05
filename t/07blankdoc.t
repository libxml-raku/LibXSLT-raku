use v6;
use Test;
plan 5;
use LibXML;
use LibXML::InputCallback;
use LibXSLT;

my $parser = LibXML.new();
my $xslt = LibXSLT.new();

# TEST
ok($parser, 'parser was initted.');
# TEST
ok($xslt, 'xslt object was initted.');

my $icb = LibXML::InputCallback.new();

# registering callbacks
$icb.register-callbacks( [ &match_cb, &open_cb,
                            &read_cb, &close_cb ] );


my $source = $parser.parse: :string(q:to<EOT>), :URI</foo>;
<?xml version="1.0" encoding="ISO-8859-1"?>
<document></document>
EOT

my $foodoc = q:to<EOT>;
<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:data="data.uri" version="1.0">
<xsl:output encoding="ISO-8859-1" method="text"/>

<data:type>typed data in stylesheet</data:type>

<xsl:template match="/*">

Data: <xsl:value-of select="document('')/xsl:stylesheet/data:type"/><xsl:text>
</xsl:text>

</xsl:template>

</xsl:stylesheet>
EOT

my $style = $parser.parse: :string($foodoc), :URI<foo>;

# TEST
ok($style, '$style is true');

my $stylesheet = $xslt.parse-stylesheet(doc => $style);
# my $stylesheet = $xslt.parse_stylesheet_file("example/document.xsl");

$stylesheet.suppress-warnings = True;
my $results = $stylesheet.transform: :doc($source);
# TEST
ok($results, 'Results are true.');
# TEST
like($results.Str, /'typed data in stylesheet'/,
    'found "typed data in stylesheet"');

###############################################################
# Callbacks - this is needed because with document('') now,
# libxslt expects to re-get the entire file and re-parse it,
# rather than its old behaviour, which was to use the internal
# DOM. So we have to use callbacks to be able to return the
# original file. We also need to make sure that the call
# to $parser.parse: :string($foodoc, 'foo') gets a URI (second
# param), otherwise it doesn't know what to fetch.

sub match_cb($uri) {
    if ($uri eq 'foo') {
        return 1;
    }
    return 0;
}

sub open_cb($uri) {
    return $foodoc.encode;
}

sub close_cb($) {
}

sub read_cb($buf is rw, $n) {
    my $rv = $buf.subbuf(0, $n);
    $buf .= subbuf(min($n, $buf.elems));
    return $rv;
}



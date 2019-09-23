use v6;
use Test;
plan 6;

my $loaded;

END {
    # TEST
    ok($loaded, 'Everything was properly loaded.');
}

use LibXSLT;
use LibXML;

$loaded = True;

# TEST
ok(1, 'Running');
my $x = LibXML.new() ;
# TEST
ok($x, 'LibXML.new works.') ;
my $p = LibXSLT.new();
# TEST
ok($p, 'LibXSLT.new works.');
my $xsl = q:to<EOF>;
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 version="1.0"> <xsl:import href="example/2.xsl" />
 <xsl:output method="html" />
</xsl:stylesheet>
EOF

my $xsld = $x.parse: :string($xsl);
# TEST
ok($xsld, 'parse_string returned a true value.') ;
my $tr = $p.parse-stylesheet($xsld) ;
# TEST
ok($tr, 'parse_stylesheet returned a true value.') ;

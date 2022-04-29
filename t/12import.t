use v6;
use Test;
plan 2;

my $loaded;

END {
    ok $loaded, 'Everything was properly loaded.';
}

use LibXSLT;
use LibXML;
use LibXML::Document;

$loaded = True;

my LibXML:D $x .= new;
my LibXSLT:D $p .= new;
my $xsl = q:to<EOF>;
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 version="1.0"> <xsl:import href="example/2.xsl" />
 <xsl:output method="html" />
</xsl:stylesheet>
EOF

lives-ok {
    my LibXML::Document:D $xsld = $x.parse: :string($xsl);
    my LibXSLT:D $tr = $p.parse-stylesheet($xsld);
}, 'parse-stylesheet succeeded.';

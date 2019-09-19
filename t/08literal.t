use v6;
use Test;
plan 8;

use LibXML;
use LibXSLT;

my $parser = LibXML.new();
my $xslt = LibXSLT.new();
# TEST
ok ($parser, '$parser was initted.');
# TEST
ok ($xslt, '$xslt was initted.');

my $source = $parser.parse: :string(q:to<EOT>);
<?xml version="1.0" encoding="ISO-8859-1"?>
<document></document>
EOT

my $style = $parser.parse: :string(q:to<EOT>);
<html
    xsl:version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>
<head>
</head>
</html>
EOT

# TEST
ok($style, '$style is true.');
my $stylesheet = $xslt.parse-stylesheet(doc => $style);

# TEST
is($stylesheet.output-method, 'xml',
    'output method is xml BEFORE processing');

# TEST
is($stylesheet.media-type, 'text/xml',
    'media_type is text/xml BEFORE processing');

my $results = $stylesheet.transform(doc => $source);

# TEST
ok($results, '$results are true.');

# TEST
is($stylesheet.output-method, 'html',
    'output method is html AFTER processing');

# TEST
is($stylesheet.media-type, 'text/html',
    'media_type is text/html AFTER processing');

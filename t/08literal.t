use v6;
use Test;
plan 5;

use LibXML;
use LibXML::Document;
use LibXSLT;
use LibXSLT::Stylesheet;

my LibXML:D $parser .= new;
my LibXSLT $xslt.= new;

my LibXML::Document:D $source = $parser.parse: :string(q:to<EOT>);
<?xml version="1.0" encoding="ISO-8859-1"?>
<document></document>
EOT

my LibXML::Document:D $style = $parser.parse: :string(q:to<EOT>);
<html
    xsl:version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>
<head>
</head>
</html>
EOT

my LibXSLT::Stylesheet:D $stylesheet = $xslt.parse-stylesheet(doc => $style);

is-deeply($stylesheet.output-method, Str,
    'html output method unknown');

is-deeply($stylesheet.media-type, Str,
    'text/html media-type unknown');

my $results = $stylesheet.transform(doc => $source);

ok $results, '$results are true.';

is $stylesheet.output-method, 'html',
    'output method is html AFTER processing';

is $stylesheet.media-type, 'text/html',
    'media_type is text/html AFTER processing';

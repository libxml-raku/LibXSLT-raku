use v6;
use Test;
plan 14;

use LibXSLT;
use LibXSLT::Stylesheet;
use LibXML;
use LibXML::Document;

my LibXML:D $parser .= new;
my LibXSLT:D $xslt .= new;

my LibXML::Document:D $source = $parser.parse: :string(q:to<EOF>);
<?xml version="1.0"?>
<foo/>
EOF

my Str @style_docs;

# XML
push @style_docs, "text/xml", q:to<EOF>;
<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:output method="xml"/>

<xsl:template match="*|@*">
<xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet>
EOF

# HTML
push @style_docs, "text/html", q:to<EOF>;
<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:output method="html"/>

<xsl:template match="*|@*">
<xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet>
EOF

# TEXT
push @style_docs, "text/plain", q:to<EOF>;
<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:output method="text"/>

<xsl:template match="*|@*">
<xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet>
EOF

# Default XML
push @style_docs, Str, q:to<EOF>;
<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:template match="*|@*">
<xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet>
EOF

# Default HTML (broken for now!)
push @style_docs, "text/html", q:to<EOF>;
<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:template match="/">
<html>
  <body>
    <xsl:apply-templates/>
  </body>
</html>
</xsl:template>

<xsl:template match="*|@*">
  <xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet>
EOF

# Text, other
push @style_docs, "text/rtf", q:to<EOF>;
<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:output method="text" media-type="text/rtf"/>

<xsl:template match="*|@*">
<xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet>
EOF

# XML, other
push @style_docs, "text/vnd.wap.wml", q:to<EOF>;
<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:output media-type="text/vnd.wap.wml" />

<xsl:template match="*|@*">
<xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet>
EOF

for @style_docs -> $media_type, $style_str {
    my LibXML::Document:D $style = $parser.parse: :string($style_str);

    my LibXSLT::Stylesheet:D $stylesheet = $xslt.parse-stylesheet(doc => $style);

    my $results = $stylesheet.transform: :doc($source);
    ok $results;

    is-deeply $stylesheet.media-type, $media_type, "media type is {$media_type.raku}";
}

use v6;
use Test;
plan 4;
use LibXSLT;

{
    use LibXML::Document;
    my LibXML::Document $doc .= parse: 'example/students.xml';
    my LibXSLT $xslt .= new;
    my LibXSLT::Security $scb .= new();
    $scb.register-callback( read-file  => &read-file );
    $xslt.security = $scb;
    my $*ALLOWED = 'example/students.xsl';
    lives-ok { $xslt.load-stylesheet-pi: :$doc; }, 'read-file accept on stylesheet load';
    my Str:D $result = $xslt.process: :$doc;
    $*ALLOWED = '';
    dies-ok { $xslt.load-stylesheet-pi: :$doc; }, 'read-file refusal on stylesheet load';
    dies-ok { $xslt.process: :$doc; }, 'read-file refusal on stylesheet processing';
}

{
    use LibXML::Document;
    use LibXSLT::Stylesheet;
    my LibXML::Document $doc .= parse: 'example/students.xml';
    my LibXSLT::Stylesheet:D $xslt = LibXSLT.load-stylesheet-pi(:$doc);
    my Str:D $result = $xslt.process: :$doc;
    pass;
}

########################################################################
#
# Security preference callbacks
#

sub read-file($tctxt, $value) {
    return $value ~~ $*ALLOWED;
}

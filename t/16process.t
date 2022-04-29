use v6;
use Test;
plan 3;
use LibXSLT;

my $debug;
# side-test on debugging
LibXSLT.set-debug-callback(-> $fmt, |args { $debug++ });

subtest 'security', {
    use LibXML::Document;
    use LibXSLT::Security;
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

subtest 'no security', {
    use LibXML::Document;
    use LibXSLT::Stylesheet;
    my LibXML::Document $doc .= parse: 'example/students.xml';
    my LibXSLT::Stylesheet:D $xslt = LibXSLT.load-stylesheet-pi(:$doc);
    my Str:D $result = $xslt.process: :$doc;
    pass;
}

ok $debug++, 'debugging detected';

########################################################################
#
# Security preference callbacks
#

sub read-file($tctxt, $value) {
    return $value ~~ $*ALLOWED;
}

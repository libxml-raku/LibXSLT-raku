use v6;
use Test;
plan 4;
use LibXSLT;
use LibXML;
use LibXSLT::Native::Defs :BIND-XSLT;
use NativeCall;
sub have-exslt(--> int32) is native(BIND-XSLT) is symbol('xslt6_config_have_exslt') {*};
constant Min-LibXSLT-Version = v1.00.00;

# TEST
ok(1, ' TODO : Add test name');

my LibXSLT:D $p .= new;

my $version = $p.version;

ok $version, 'LibXSLT.version is trueish';

diag "Running libxslt version: $version (module {LibXSLT.^ver})";
with LibXSLT.config-version {
    diag "***NOTE was configured against libxslt version $_ ***"
        unless $_ == LibXSLT.version
}
diag "Running libxml version: {LibXML.version} (module {LibXML.^ver})";
diag "Running libexslt? " ~ ( have-exslt() ?? 'Yes' !! 'No');

ok($version >= Min-LibXSLT-Version, "LibXSLT version is suppported")
or diag "sorry this version of libxslt is not supported ($version < {Min-LibXSLT-Version})";

{
    use LibXML::Document;
    my LibXML::Document $xml .= parse(location => 'example/1.xml');
    my LibXML::Document $xsl .= parse(location=>'example/1.xsl', :!cdata);

    my Str:D $result = LibXSLT.process: :$xml, :$xsl;
    ok $result, 'XSLT .process() sanity';
}



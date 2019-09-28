use v6;
use Test;
plan 3;
use LibXSLT;

constant Min-LibXSLT-Version = v1.00.00;

# TEST
ok(1, ' TODO : Add test name');

my LibXSLT:D $p .= new;

my $version = $p.version;

ok $version, 'LibXSLT.version is trueish';

diag "Running libxslt version: " ~ $version;

ok($version >= Min-LibXSLT-Version, "LibXSLT version is suppported")
    or diag "sorry this version of libxslt is not supported ($version < {Min-LibXSLT-Version})";


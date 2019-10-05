use v6;
use Test;
plan 30;
use LibXSLT;
use LibXSLT::Security;
use LibXSLT::TransformContext;
use LibXML;
use LibXML::InputCallback;
use LibXSLT::Native::Defs :BIND-XSLT;
use NativeCall;

sub have-exslt(--> int32) is native(BIND-XSLT) is symbol('xslt6_config_have_exslt') {*};

my LibXML $parser .= new();
print "# parser\n";
# TEST
ok($parser, ' TODO : Add test name');

my $xslt = LibXSLT.new();
print "# xslt\n";
# TEST
ok($xslt, ' TODO : Add test name');

my $stylsheetstring = q:to<EOT>;
<xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns="http://www.w3.org/1999/xhtml"
      xmlns:exsl="http://exslt.org/common"
      extension-element-prefixes="exsl">

<xsl:template match="/">
<html>
<head><title>Know Your Dromedaries</title></head>
<body>
  <h1><xsl:apply-templates/></h1>
  <xsl:choose>
    <xsl:when test="file">
      <p>foo: <xsl:apply-templates select="document(file)/*" /></p>
    </xsl:when>
    <xsl:when test="write">
      <exsl:document href="{write}">
       <outfile><xsl:value-of select="write"/></outfile>
      </exsl:document>
      <p>wrote: <xsl:value-of select="write"/></p>
    </xsl:when>
    <xsl:otherwise>
     No file given
    </xsl:otherwise>
  </xsl:choose>
</body>
</html>
</xsl:template>

</xsl:stylesheet>
EOT

# We're using input callbacks so that we don't actually need real files while
# testing the security callbacks
my $icb = LibXML::InputCallback.new();
# TEST
ok($icb, ' TODO : Add test name');

print "# registering input callbacks\n";
$icb.register-callbacks( [ &match-cb, &open-cb,
                            &read-cb, &close-cb ] );
$xslt.input-callbacks($icb);

my $scb = LibXSLT::Security.new();
# TEST
ok($scb, ' TODO : Add test name');

unless have-exslt() {
    skip-rest "libexslt required for remaining tests";
    exit;
}

print "# registering security callbacks\n";
$scb.register-callback( read-file  => &read-file );
$scb.register-callback( write-file => &write-file );
$scb.register-callback( create-dir => &create_dir );
$scb.register-callback( read-net   => &read-net );
$scb.register-callback( write-net  => &write-net );

$xslt.security = $scb;

my $stylesheet = $xslt.parse-stylesheet($parser.parse: :string($stylsheetstring));
print "# stylesheet\n";

# TEST
ok($stylesheet, ' TODO : Add test name');

# test local read
# ---------------------------------------------------------------------------
# - test allowed
my $doc = $parser.parse: :string('<file>allow.xml</file>');
{
    my LibXSLT::TransformContext $ctx .= new: :$doc, :$stylesheet;
    ok $scb.check-read($ctx, 'allow.xml'), '.checkread() # allowed';
    nok $scb.check-read($ctx, 'deny.xml'), '.checkread() # !allowed';
    try { $ctx.flush-errors }
}

my $results = $stylesheet.transform($doc).Xslt;
print "# local read results\n";
# TEST
ok($results, ' TODO : Add test name');

my $output = $results.Str;
#warn "output: $output\n";
print "# local read output\n";
# TEST
like($output, /'foo: Text here'/, 'Output matches foo');

# - test denied
$doc = $parser.parse: :string('<file>deny.xml</file>');
try {
   $results = $stylesheet.transform($doc);
};
{
    my $E = $!;
    print "# local read denied\n";
    # TEST
   like($E.message, /'read for deny.xml refused'/, 'Exception gives read for deny.xml');
}

# test local write & create dir
# ---------------------------------------------------------------------------
# - test allowed (no create dir)
my $file = 't/allow.xml';
$doc = $parser.parse: :string("<write>{$file}</write>");
$results = $stylesheet.transform($doc).Xslt;
print "# local write (no create dir) results\n";
# TEST
ok($results, ' TODO : Add test name');

$output = $results.Str;
#warn "output: $output\n";
print "# local write (no create dir) output\n";
# TEST
like($output, /'wrote: '$file/, 'Output matches wrote.');

# TEST
ok($file.IO.s, ' TODO : Add test name');
unlink $file;

# - test allowed (create dir)
$file = 't/newdir/allow.xml';
$doc = $parser.parse: :string("<write>{$file}</write>");
$results = $stylesheet.transform($doc).Xslt;
print "# local write (create dir) results\n";
# TEST
ok($results, ' TODO : Add test name');

$output = $results.Str;
#warn "output: $output\n";
print "# local write (create dir) output\n";
# TEST
like($output, /'wrote: '$file/, 'Output matches wrote');

print "# local write (create dir) file exists\n";
# TEST
ok($file.IO.s, 'File has non-zero size.');
unlink $file;
rmdir 't/newdir';

# - test denied (no create dir)
$file = 't/deny.xml';
$doc = $parser.parse: :string("<write>{$file}</write>");
try {
   $results = $stylesheet.transform($doc);
};
print "# local write (no create dir) denied\n";
{
    my $E = $!;
# TEST
    like($E.message, /'write for '$file' refused'/, 'exception matches');
}
# TEST
ok((! $file.IO.e), 'File does not exist.');
# - test denied (create dir)


$file = 't/baddir/allow.xml';
$doc = $parser.parse: :string("<write>{$file}</write>");
try {
   $results = $stylesheet.transform($doc);
};
print "# local write (create dir) denied\n";
{
    my $E = $!;
    # TEST
    like($E, /'creation for '$file' refused'/, 'creation for file refused');
}
# TEST
ok((!$file.IO.e), 'File does nto exist - create dir.');

# test net read
# ---------------------------------------------------------------------------
# - test allowed
$doc = $parser.parse: :string('<file>http://localhost/allow.xml</file>');
$results = $stylesheet.transform($doc).Xslt;
print "# net read results\n";
# TEST
ok($results, ' TODO : Add test name');

$output = $results.Str;
#warn "output: $output\n";
print "# net read output\n";
# TEST
like($output, /'foo: Text here'/, 'Output matches.');

# - test denied
$doc = $parser.parse: :string('<file>http://localhost/deny.xml</file>');
try {
   $results = $stylesheet.transform($doc).Str;
};
print "# net read denied\n";
{
    my $E = $!;
    # TEST
    like($E, /'read for http://localhost/deny.xml refused'/,
    'Exception read for refused.'
);
}

# test net write
# ---------------------------------------------------------------------------
# - test allowed
{

    my $port = 8080;
    my $listener = IO::Socket::Async.listen('127.0.0.1', $port);
    $listener.tap({.print("<blah/>\n"); .close });
$file = "http://localhost:{$port}/allow.xml";
$doc = $parser.parse: :string("<write>{$file}</write>");
try {
   $results = $stylesheet.transform($doc).Xslt;
};
print "# net write allowed\n";
{
    my $E = $!;
# TEST
like($E, /'unable to save to '$file/,
    'unable to save exception');
}
}

# - test denied
$file = 'http://localhost/deny.xml';
$doc = $parser.parse: :string("<write>{$file}</write>");
try {
   $results = $stylesheet.transform($doc).Xslt;
};
print "# net write denied\n";
{
    my $E = $!;
# TEST
like($E, /'write for '$file' refused'/, 'Exception write refused');

}

# test a dying security callback (and resetting the callback object through
# the stylesheet interface).
# ---------------------------------------------------------------------------
my $scb2 = LibXSLT::Security.new();
$scb2.register-callback( read-file => &read-file-die );
$stylesheet.security = $scb2;

# check if transform throws an exception
$doc = $parser.parse: :string('<file>allow.xml</file>');
print "# dying callback test\n";
try {
    $stylesheet.transform($doc);
};
{
    my $E = $!;
# TEST
like($E, /'Test die from security callback'/,
    'Exception Test die from security callback.');

}

done-testing();

########################################################################
#
# Security preference callbacks
#
# TEST:$read-file=1;
sub read-file($tctxt, $value) {
   print "# security read-file: $value\n";
   if ($value eq 'allow.xml') {
      print "# transform context\n";
      # TEST*$read-file
      isa-ok( $tctxt, "LibXSLT::TransformContext", ' TODO : Add test name' );
      print "# stylesheet from transform context\n";
      # TEST*$read-file
      isa-ok( $tctxt.stylesheet, "LibXSLT::Stylesheet", ' TODO : Add test name' );
      return 1;
   }
   else {
      return 0;
   }
}

sub read-file-die($tctxt, $value) {
   print "# security read-file-die: $value\n";
   die "Test die from security callback";
}

sub write-file($tctxt, $value) {
   print "# security write-file: $value\n";
   if ($value ~~ /'allow.xml'|newdir|baddir/) {
      return 1;
   }
   else {
      return 0;
   }
}

sub create_dir($tctxt, $value) {
   print "# security create_dir: $value\n";
   if ($value ~~ /newdir/) {
      return 1;
   }
   else {
      return 0;
   }
}

sub read-net($tctxt, $value) {
   print "# security read-net: $value\n";
   if ($value ~~ /'allow.xml'/) {
      return 1;
   }
   else {
      return 0;
   }
}

sub write-net($tctxt, $value) {
   print "# security write-net: $value\n";
   if ($value ~~ /'allow.xml'/) {
      return 1;
   }
   else {
      return 0;
   }
}


#
# input callback functions (used so we don't have to have an actual file)
#
sub match-cb($uri) {
    # print "# input match-cb: $uri\n";
    if ($uri ~~ /[allow|deny]'.xml'/) {
        return 1;
    }
    return 0;
}

sub open-cb($uri) {
    # print "# input open-cb: $uri\n";
    my $str = "<foo>Text here</foo>";
    return $str.encode;
}

sub close-cb($) {
    # print "# input close-cb\n";
}

sub read-cb($buf is rw, $n) {
    # print "# read $n\n";
    my $rv = $buf.subbuf(0, $n);
    $buf .= subbuf(min($n, $buf.elems));
    return $rv;
}


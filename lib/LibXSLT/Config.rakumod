unit class LibXSLT::Config;

use LibXSLT::Raw;

method have-exslt { ? xslt6_config_have_exslt(); }
method config-version { Version.new: xslt6_config_version(); }
method version { int-to-version(xsltLibxsltVersion) }
method max-depth is rw {
    Proxy.new(
        :FETCH{ xsltMaxDepth() },
        STORE => -> $, Int:D() $val {
            xslt6_gbl_set_max_depth($val);
        }
    );
}
method max-vars is rw {
    Proxy.new(
        :FETCH{ xsltMaxVars() },
        STORE => -> $, Int:D() $val {
            xslt6_gbl_set_max_vars($val);
        }
    );
}

sub int-to-version(Int $v) {
    Version.new: [$v div 10_000, ($v div 100) % 100,  $v % 100];
}

=begin pod
=head1 NAME

LibXSLT::Config - LibXSLT Global configuration

=head1 SYNOPSIS



  use LibXSLT::Config;

=head1 METHODS

=begin item1
have-exslt

Returns True if the `libexslt` library is available in this build.
=end item1

=end pod

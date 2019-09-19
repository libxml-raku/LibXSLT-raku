unit class LibXSLT::Config;

use LibXSLT::Native;

method have-exslt { ? xslt6_gbl_have_exslt(); }

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

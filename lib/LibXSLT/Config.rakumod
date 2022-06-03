unit class LibXSLT::Config;

use LibXSLT::Raw;

my Lock:D $lock .= new;

method have-exslt { ? xslt6_config_have_exslt(); }
method config-version { Version.new: xslt6_config_version(); }
method version { int-to-version(xsltLibxsltVersion) }
method max-depth is rw {
    Proxy.new(
        :FETCH{ $lock.protect: { xsltMaxDepth() } },
        STORE => -> $, Int:D() $val {
            $lock.protect: {
                xslt6_gbl_set_max_depth($val);
            }
        }
    );
}
method max-vars is rw {
    Proxy.new(
        :FETCH{  $lock.protect: { xsltMaxVars() } },
        STORE => -> $, Int:D() $val {
            $lock.protect: {
                xslt6_gbl_set_max_vars($val);
            }
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
  LibXSLT::Config.max-vars = 2000;
  # -- OR --
  use LibXSLT;
  LibXSLT.max-vars = 2000;

This is a singleton class that handles global configuration settings.

The only updatable settings are `max-depth` and `max-vars`. These should
usually be set once at program initialization.

L<LibXSLT> handles has all of the settings method available, so there
is not usually any need to work with this class directly.

=head1 METHODS

=defn have-exslt
Returns True if the `libexslt` library is available in this build.

=defn version
The current version of `libxslt`

=defn build-version
The version of `libxslt` that the Raku bindings were built against. This
may vary if `libxslt` has been upgraded since this Raku module was built.

=defn max-depth
This option sets the maximum recursion depth for a stylesheet. See the very end of section 5.4 of the XSLT specification for more details on recursion and detecting it. If your stylesheet or XML file requires seriously deep recursion, this is the way to set it.

=defn max-vars
This option sets the maximum number of variables for a stylesheet. If your stylesheet or XML file requires many variables, this is the way to increase their limit. Default value is system-specific and may vary.

=end pod

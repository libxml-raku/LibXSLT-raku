unit class LibXSLT::Security;

use LibXSLT::Raw;
use LibXSLT::Enums;
use LibXML::ErrorHandling;
use LibXML::Enums;

has xsltSecurityPrefs $!raw;

class X::LibXSLT::AdHoc is X::LibXML::AdHoc {
    method domain-num {XML_FROM_XSLT}
}

submethod TWEAK {
    $!raw .= new();
}

submethod DESTROY {
    .Free with $!raw;
}

method !set-security-pref(Int() $pref, &func) {
    $!raw.Set($pref, -> $sec, $ctx, $val --> Int {
        my Int $rv = try { &func($*XML-CONTEXT, $val); } // 0;
        with $! {
            $*XML-CONTEXT.callback-error(X::LibXSLT::AdHoc.new(:error($_)));
            $rv = -1;
        }
        $rv;
    });
}

multi method register-callback(:&read-file!) {
    self!set-security-pref(XSLT_SECPREF_READ_FILE, &read-file);
}

multi method register-callback(:&write-file!) {
    self!set-security-pref(XSLT_SECPREF_WRITE_FILE, &write-file);
}

multi method register-callback(:&create-dir!) {
    self!set-security-pref(XSLT_SECPREF_CREATE_DIRECTORY, &create-dir);
}

multi method register-callback(:&read-net!) {
    self!set-security-pref(XSLT_SECPREF_READ_NETWORK, &read-net);
}

multi method register-callback(:&write-net!) {
    self!set-security-pref(XSLT_SECPREF_WRITE_NETWORK, &write-net);
}

method register-callbacks(*%callbacks) {
    self.register-callback(|$_)
        for %callbacks.sort;
}

method allow(Str $thing) {
    $!raw.Allow($thing);
}

method forbid(Str $thing) {
    $!raw.Forbid($thing);
}

method set-default {
    with self { $!raw.SetDefault(); } else { xsltSecurityPrefs.SetDefault(); }
}

method set-context($ctx) {
    $!raw.SetContext(.raw) with $ctx;
}

method check-read($*XML-CONTEXT, Str $url) {
    given $!raw.CheckRead($*XML-CONTEXT.raw, $url) {
        when 1 { True }
        when 0 { False }
        default { fail "check-read failed with status: $_" }
    }
}

method check-write($*XML_CONTEXT, Str $url) {
    given $!raw.CheckWrite($*XML-CONTEXT.raw, $url) {
        when 1 { True }
        when 0 { False }
        default { fail "check-write failed with status: $_" }
    }
}

=begin pod

=head1 NAME

LibXSLT::Security

=head1 DESCRIPTION

Provides an interface to the libxslt security framework by allowing callbacks
to be defined that can restrict access to various resources (files or URLs)
during a transformation.

The libxslt security framework allows callbacks to be defined for certain
actions that a stylesheet may attempt during a transformation. It may be
desirable to restrict some of these actions (for example, writing a new file
using exsl:document). The actions that may be restricted are:

=begin item
read-file

Called when the stylesheet attempts to open a local file (ie: when using the
document() function).
=end item

=begin item
write-file

Called when an attempt is made to write a local file (ie: when using the
exsl:document element).
=end item

=begin item
create-dir

Called when a directory needs to be created in order to write a file.

NOTE: By default, create_dir is not allowed. To enable it a callback must be
registered.
=end item

=begin item
read-net

Called when the stylesheet attempts to read from the network.
=end item

=begin item
write-net

Called when the stylesheet attempts to write to the network.

=end item

=head2 Using LibXSLT::Security

The interface for this module is similar to LibXML::InputCallback. After
creating a new instance you may register callbacks for each of the security
options listed above. Then you apply the security preferences to the
LibXSLT or LibXSLT::Stylesheet object using C<security_callbacks()>.

  my LibXSLT::Security $security .= new();
  $security.register-callback( read-file  => &read-cb );
  $security.register-callback( write-file => &write-cb );
  $security.register-callback( create-dir => &create-cb );
  $security.register-callback( read-net   => &read-net-cb );
  $security.register-callback( write-net  => &write-net-cb );

  $xslt.security-callbacks( $security );
   -OR-
  $stylesheet.security-callbacks( $security );


The registered callback functions are called when access to a resource is
requested. If the access should be allowed the callback should return True, if
not it should return False. The callback functions should accept the following
arguments:


=begin item
LibXSLT::TransformContext $tctxt

This is the transform context. You can use
this to get the current LibXSLT::Stylesheet object by calling
C<stylesheet()>.

  my $stylesheet = $tctxt.stylesheet();

The stylesheet object can then be used to share contextual information between
different calls to the security callbacks.
=end item

=begin item
Str $value

This is the name of the resource (file or URI) that has been requested.

=end item

If a particular option (except for C<create-dir>) doesn't have a registered
callback, then the stylesheet will have full access for that action.

=head2 Interface

=begin item
new()

Creates a new LibXSLT::Security object.
=end item

=begin item
register-callback( $option, &callback )

Registers a callback function for the given security option (listed above).
=end item

=begin item
unregister-callback( $option )

Removes the callback for the given option. This has the effect of allowing all
access for the given option (except for C<create_dir>).
=end item


=end pod

unit class LibXSLT::Security;

use LibXSLT::Native;
use LibXSLT::Enums;
has xsltSecurityPrefs $!native;

submethod TWEAK {
    $!native .= new();
}

submethod DESTROY {
    .Free with $!native;
}

method !set-security-pref(Int() $pref, &func) {
    $!native.Set($pref, -> $sec, $ctx, $val --> Int {
        CATCH { default { warn $_; $*XML-CONTEXT.callback-error($_); return 0} }
        my Int $rv := &func($*XML-CONTEXT, $val);
        $rv // 0;
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
    $!native.Allow($thing);
}

method forbid(Str $thing) {
    $!native.Forbid($thing);
}

method set-default {
    $!native.SetDefault();
}


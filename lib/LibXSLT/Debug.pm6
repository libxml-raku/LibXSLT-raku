use v6;
unit class LibXSLT::Debug;

has &.callback;

method debug-callback {
    -> $ctx, $fmt, *@args {
        my $msg = $fmt.subst('%s', {nativecast(Str, @args.shift)}, :g);
        note $msg;
    }
}

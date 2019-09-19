#! /usr/bin/env perl6
#Note `zef build .` will run this script
use v6;

class Build {
    use NativeCall;

    sub have-exslt {
        sub exsltRegisterAll() is native('exslt') {*}
        try { exsltRegisterAll() };
        ! $!.defined;
    }

    need LibraryMake;
    # adapted from deprecated Native::Resources
    #| Sets up a C<Makefile> and runs C<make>.  C<$folder> should be
    #| C<"$folder/resources/lib"> and C<$libname> should be the name of the library
    #| without any prefixes or extensions.
    sub make(Str $folder, Str $destfolder, IO() :$libname!) {
        my %vars = LibraryMake::get-vars($destfolder);
        %vars<LIB-NAME> = ~ $*VM.platform-library-name($libname);
        %vars<LIB-CFLAGS> = '-I/usr/include/libxslt -I/usr/include/libxml2';
        my @libs = <xslt xml2>;
        if have-exslt() {
            @libs.unshift: 'exslt';
            %vars<CCFLAGS> ~= ' -DXSLT6_HAVE_EXSLT';
        }
        if $*VM.config<dll> ~~ /dll/ {
            %vars<LIB-LDFLAGS> = @libs.map({"-llib{$_}"}).join: ' ';
        }
        else {
            %vars<LIB-LDFLAGS> = @libs.map({"-l{$_}"}).join: ' ';
        }
        s/:s '-DNDEBUG'// for %vars<CCFLAGS>, %vars<LDFLAGS>;

        mkdir($destfolder);
        LibraryMake::process-makefile($folder, %vars);
        shell(%vars<MAKE>);
    }

    method build($workdir) {
        my $destdir = 'resources/libraries';
        mkdir $destdir;
        make($workdir, "$destdir", :libname<xslt6>);
        True;
    }
}

# Build.pm can also be run standalone
sub MAIN(Str $working-directory = '.' ) {
    Build.new.build($working-directory);
}

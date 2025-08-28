use LibXML::Document;
use LibXSLT;
use LibXSLT::Config;
use LibXSLT::Document;
use LibXSLT::Stylesheet;

sub MAIN(Str $doc-loc, Str :$xsl, UInt :$maxvars, UInt :$maxdepth) {

    LibXSLT::Config.max-vars  = $_ with $maxvars;
    LibXSLT::Config.max-depth = $_ with $maxdepth;

    my LibXSLT:D $xslt .= new;
    my LibXML::Document $doc;
    my LibXSLT::Stylesheet $stylesheet;

    with $xsl -> $file {
        $stylesheet = $xslt.parse-stylesheet(:$file);
    }
    with $doc-loc -> $location {
        $doc .= parse:
            |($doc-loc eq '-'
              ?? :string($*IN.slurp-rest)
	      !! :location($doc-loc)
             );
        $stylesheet //= LibXSLT::Stylesheet.load-stylesheet-pi(:$doc);
    }

    with $stylesheet {
        my LibXSLT::Document::Xslt $results = .transform(:$doc).Xslt;
        say $results.Str;
    }
    else {
        die "unable to locate a stylesheet";
    }
}

=begin pod

=head1 NAME

xslt.raku - Run a simple XSLT transform

=head1 SYNOPSIS

xslt.raku [-xsl=<stylesheet>] <doc>

Options:
   --xsl           external stylesheet location
   --maxdepth=n   maximum depth for deeply recursive documents
   --maxvars=m    maximum number of variables for complex documents

=head1 DESCRIPTION

Tiny Raku script to run an XSLT transformation using LibXSLT.

Result is output to stdout.

=cut

=end pod

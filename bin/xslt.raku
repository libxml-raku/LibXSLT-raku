use LibXML::Document;
use LibXSLT;
use LibXSLT::Document;
use LibXSLT::Stylesheet;

sub MAIN(Str $doc-loc, Str :$xsl) {
    my LibXSLT $xslt .= new;
    my LibXML::Document $doc;
    my LibXSLT::Stylesheet $stylesheet;

    with $xsl -> $file {
        $stylesheet = $xslt.parse-stylesheet(:$file);
    }
    with $doc-loc -> $location {
        $doc .= parse(location => $doc-loc);
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
   --xsl         external stylesheet location

=head1 DESCRIPTION

Tiny Raku script to run an XSLT transformation using LibXSLT.

Result is output to stdout.

=cut

=end pod

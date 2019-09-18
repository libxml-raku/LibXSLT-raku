use v6;
use LibXSLT::Document;

use LibXSLT::Stylesheet;
unit class LibXSLT
    is LibXSLT::Stylesheet;

our sub xpath-to-string(*%xpath) {
    %xpath.map: {
        my $key = .key.subst(':', '_', :g);
        my $value = .value // '';
        my $string = $value ~~ s:g/\'/', "'", '/
            ?? "concat('$value')"
            !! "'{$value}'";
       $key => $string;
    }
}

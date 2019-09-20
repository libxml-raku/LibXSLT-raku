use v6;
use LibXSLT::Document; # help Rakudo

use LibXSLT::Stylesheet;
unit class LibXSLT
    is LibXSLT::Stylesheet;

use LibXSLT::Config;
use LibXSLT::Native;
use LibXML::Native;
use LibXML::XPath::Context :get-value;
use LibXML::Types :NCName, :QName;
use Method::Also;

method config handles<have-exslt> {
    LibXSLT::Config;
}

method register-function(Str $url, QName:D $name, &func, |c) {
    xsltRegisterExtModuleFunction(
        $name, $url,
        -> xmlXPathParserContext $ctxt, Int $n {
            CATCH { default { warn $_; $*XML-CONTEXT.callback-error: X::LibXML::XPath::AdHoc.new: :error($_) } }
            my @params;
            @params.unshift: get-value($ctxt.valuePop) for 0 ..^ $n;
            my $ret = &func(|@params, |c);
            my xmlXPathObject:D $out := xmlXPathObject.coerce: $*XML-CONTEXT.park($ret, :$ctxt);
            $ctxt.valuePush($_) for $out;
        }
    );
}

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

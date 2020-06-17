unit class LibXSLT::ExtensionContext;

use LibXSLT::Raw;
use LibXML::Raw;
use LibXML::Node;
has xsltElemPreComp $!comp;

has anyNode  $!source-raw;
has LibXML::Node $!source;
method source-node { $!source //= LibXML::Node.box($!source-raw); }

has anyNode  $!style-raw;
has LibXML::Node $!style;
method style-node { $!style //= LibXML::Node.box($!style-raw); }

has anyNode  $!insert-raw;
has LibXML::Node $!insert;
method insert-node { $!insert //= LibXML::Node.box($!insert-raw); }

submethod TWEAK(anyNode :$!source-raw!, anyNode :$!insert-raw!, xsltElemPreComp:D :$!comp!, :$!style-raw) {
    $!style-raw //= $!comp.inst;
}

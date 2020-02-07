unit class LibXSLT::ExtensionContext;

use LibXSLT::Native;
use LibXML::Native;
use LibXML::Node;
has xsltElemPreComp $!comp;

has anyNode  $!source-native;
has LibXML::Node $!source;
method source-node { $!source //= LibXML::Node.box($!source-native); }

has anyNode  $!style-native;
has LibXML::Node $!style;
method style-node { $!style //= LibXML::Node.box($!style-native); }

has anyNode  $!insert-native;
has LibXML::Node $!insert;
method insert-node { $!insert //= LibXML::Node.box($!insert-native); }

submethod TWEAK(anyNode :$!source-native!, anyNode :$!insert-native!, xsltElemPreComp:D :$!comp!, :$!style-native) {
    $!style-native //= $!comp.inst;
}

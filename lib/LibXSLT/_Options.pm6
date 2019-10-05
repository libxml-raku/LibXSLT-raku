unit role LibXSLT::_Options;

use LibXML::_Options;

has Bool $.suppress-warnings is rw;
has Bool $.suppress-errors is rw;

also does LibXML::_Options[
    %( :suppress-warnings, :suppress-errors )
    ];

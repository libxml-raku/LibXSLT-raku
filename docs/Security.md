[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXSLT Module]](https://libxml-raku.github.io/LibXSLT-raku)
 / [Security](https://libxml-raku.github.io/LibXSLT-raku/Security)

NAME
====

LibXSLT::Security

DESCRIPTION
===========

Provides an interface to the libxslt security framework by allowing callbacks to be defined that can restrict access to various resources (files or URLs) during a transformation.

The libxslt security framework allows callbacks to be defined for certain actions that a stylesheet may attempt during a transformation. It may be desirable to restrict some of these actions (for example, writing a new file using exsl:document). The actions that may be restricted are:

  * read-file

    Called when the stylesheet attempts to open a local file (ie: when using the document() function).

  * write-file

    Called when an attempt is made to write a local file (ie: when using the exsl:document element).

  * create-dir

    Called when a directory needs to be created in order to write a file.

    NOTE: By default, create_dir is not allowed. To enable it a callback must be registered.

  * read-net

    Called when the stylesheet attempts to read from the network.

  * write-net

    Called when the stylesheet attempts to write to the network.

Using LibXSLT::Security
-----------------------

The interface for this module is similar to LibXML::InputCallback. After creating a new instance you may register callbacks for each of the security options listed above. Then you apply the security preferences to the LibXSLT or LibXSLT::Stylesheet object using `security_callbacks()`.

    my LibXSLT::Security $security .= new();
    $security.register-callback( read-file  => &read-cb );
    $security.register-callback( write-file => &write-cb );
    $security.register-callback( create-dir => &create-cb );
    $security.register-callback( read-net   => &read-net-cb );
    $security.register-callback( write-net  => &write-net-cb );

    $xslt.security-callbacks( $security );
     -OR-
    $stylesheet.security-callbacks( $security );

The registered callback functions are called when access to a resource is requested. If the access should be allowed the callback should return True, if not it should return False. The callback functions should accept the following arguments:

  * LibXSLT::TransformContext $tctxt

    This is the transform context. You can use this to get the current LibXSLT::Stylesheet object by calling `stylesheet()`.

        my $stylesheet = $tctxt.stylesheet();

    The stylesheet object can then be used to share contextual information between different calls to the security callbacks.

  * Str $value

    This is the name of the resource (file or URI) that has been requested.

If a particular option (except for `create-dir`) doesn't have a registered callback, then the stylesheet will have full access for that action.

Interface
---------

  * new()

    Creates a new LibXSLT::Security object.

  * register-callback( $option, &callback )

    Registers a callback function for the given security option (listed above).

  * unregister-callback( $option )

    Removes the callback for the given option. This has the effect of allowing all access for the given option (except for `create_dir`).


[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXSLT Module]](https://libxml-raku.github.io/LibXSLT-raku)

NAME
====

LibXSLT::Config - LibXSLT Global configuration

SYNOPSIS
========

    use LibXSLT::Config;
    LibXSLT::Config.max-vars = 2000;
    # -- OR --
    use LibXSLT;
    LibXSLT.max-vars = 2000;

This is a singleton class that handles global configuration settings.

The only updatable settings are `max-depth` and `max-vars`. These should usually be set once at program initialization.

[LibXSLT](https://libxml-raku.github.io/LibXSLT-raku) handles has all of the settings method available, so there is not usually any need to work with this class directly.

METHODS
=======

**have-exslt**

Returns True if the `libexslt` library is available in this build.

**version**

The current version of `libxslt`

**build-version**

The version of `libxslt` that the Raku bindings were built against. This may vary if `libxslt` has been upgraded since this Raku module was built.

**max-depth**

This option sets the maximum recursion depth for a stylesheet. See the very end of section 5.4 of the XSLT specification for more details on recursion and detecting it. If your stylesheet or XML file requires seriously deep recursion, this is the way to set it.

**max-vars**

This option sets the maximum number of variables for a stylesheet. If your stylesheet or XML file requires many variables, this is the way to increase their limit. Default value is system-specific and may vary.


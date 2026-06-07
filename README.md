# TL::Helper

Provide simple help for Getopt::Long

# SYNOPSIS

    use Getopt::Long;
    use TL::Helper( qw/getoptions help );

    my( $help, $version );
    my @options = ( 'help|h' => \$help => 'This help', man => \$man, '',
                    version  => \$version, '' );

    GetOptions( getoptions( \@options ) ) or die( "Command error\n" );

    help( \@options ) if( $help );
    man               if( $man );
    version           if( $version );

# DESCRIPTION

**TL::Helper** provides a simple help function for Getopt::Long's options.

By including the help in the options array, maintenance is simpler than
updating POD and implemeting quick utilities can still provide help with
minimal effort.

The help text for each option is a string included as a third element
to each pair of `switch => target` in _Getopt::Long_'s input array.

If no information is to be provided for an uption, specify `undef`.

If no help is to be provided for an option, specify an empty string.

The options array's size must be an even multiple of three.

# _getoptions( $options )_

_getoptions_ takes a reference to the options array.

Normally (in array context), it returns a copy of the array with the help
strings removed, which can be used by `Getopt::Long::GetOptions()`.

In void context, it updates the input array, rendering it useable for
`Getopt::Long`, but useless for help.

In scalar context, it returns a reference to a copy of the array with
the help strings removed.

# _help( $options, $cmdargs, $fh )_

_help_ requires a reference to the options array.

`$cmdargs` summarizes any non-option arguments, e.g. `'[infile] [outfile]'`.  Omit
or use `undef` if none.

If multiple command forms exist, separate with C\\n> or provide a reference to an array.  Preceede each item after the first with `_` if repeating`[options]` is desired.

In void context, it outputs help to `$fh`, defaulting to `STDOUT`.  It then exits.

Otherwise, it returns the help as a string.

# _man( $fh )_

_man_ provides the program's POD as a man page.

In void context, it writes to `$fh`, or `STDOUT`.

Otherwise, if `$fh` is specified, it writes to `STDOUT` and returns true.

If no `$fh` is specified, it returns the manual as a string.

# _version( \[$fh\] \[,\\@others\] \[,$options | ,@options...\] )_

_version_ provides the version of the caller and this module.

In void context, it outputs the version to `$fh`, defaulting to `STDOUT`.  It then exits.

Otherwise, it returns the version as a string.

`@options` specifies the format of the version string.

- `withdate`

    If true, includes the main script's last modified date, even if it has a `$VERSION`.

- `withhelper`

    If true, includes the version of `TL::Helper`

- `commit[:$length]`

    If `$VERSION` looks like a `git` commit id, prefix it with `git-` and
    truncate it to $length digits (default 7).  Set $length to 0 to inhibit.

- `vstring:$fmt`

    If `$VERSION` is a vstring, `$fmt` is the `sprintf` conversion code.
    Default is `u`; other numeric codes (e.g. `o`, `x` can be used.

The default is to only include the date if `$VERSION` is undefined, and to
include the version of `TL::Helper`.  If any option is specified, no
default is applied.  For just the main script's version, use `withhelper:0`.

If a hashref is provided, the keys are the options and values should be true (1)
for boolean options or the desired value.

If an arrayref is provided, the contents are package names whose `$VERSION`s
are alos included.  This should be limited to key dependencies.

If an option list is provided, values may be specified by appending `:value`
to the option name.  (`=` may be used instead of `:`).

# BUGS

Report any bugs, feature requests and/or patches to the author.

# AUTHOR

Timothe Litt  <litt@acm.org>


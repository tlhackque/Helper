# -*- cperl -*-

# Copyright is in the POD at the end of this file.

package TL::Helper;

our $VERSION = 'V1.1';

use warnings;
use strict;

use Carp;
use File::Basename;
use FindBin(      qw/$Bin $Script/ );
use Scalar::Util( qw/isvstring reftype/ );

require Exporter;
our @ISA       = ( qw(Exporter) );
our @EXPORT_OK = ( qw/help getoptions man version/ );

sub getoptions;
sub help;
sub man;
sub version;
sub _version;
sub _commit;
sub _date;

my $prog = basename( $0, qw/.pl/ );

# Return just the Getopt::Long slice of the options array (removing help)

sub getoptions {
    my( $options ) = @_;

    croak( "Invalid options array\n" ) if( @$options == 0 || @$options % 3 );

    my @opts;
    for( my $i = 0; $i < @$options; $i += 3 ) {
        my( $opt, $dst ) = @{$options}[ $i, $i + 1 ];
        croak( "Invalid options array\n" ) if( ref $opt || !ref $dst );
        push @opts, $opt, $dst;
    }

    # In void context, update input array (discarding help)

    unless( defined wantarray ) {
        @$options = @opts;
        return;
    }

    # Return list or reference depending on context

    return @opts if( wantarray );
    return \@opts;
}

# Display/return help for options in array

sub help {
    my( $options, $cmdargs, $fh ) = @_;

    croak( "Invalid options array\n" )
        if( ref $options ne 'ARRAY' or @$options == 0 || @$options % 3 );

    # Parse option specifiers

    my %flags = ( i   => [ 0, q(Integer argument) ],
                  f   => [ 0, q(Floating point argument) ],
                  s   => [ 0, q(String, usually filename argument) ],
                  '*' => [ 0, q(Option can be repeated) ],
                );

    my( $tw, @opts, @optw ) = ( 1 );
    for( my $i = 0; $i < @$options; $i += 3 ) {
        my( $opt, $dst, $help ) = @{$options}[ $i .. $i + 2 ];

        croak( "Invalid options array\n" ) if( ref $opt || !ref $dst );

        next unless( defined $help );

        # Specs usually validated by GetOption parsing --help.  But might be called with
        # a different table.

        unless( $opt =~ /^([^=:+!]+)(?:([=:])([ifs])|([+!]))?$/ ) {
            croak( "Invalid option spec $opt\n" );
        }
        my( $keys, $delim, $type, $mod ) = ( $1, $2, $3, $4 );

        $delim //= '';
        $type  //= '';
        $tw      = length $type if( length $type > $tw );
        $mod   //= '';
        my $not  = $mod eq '!';
        my @keys = split( /\|/, $keys );

        # Each name (keyword) for this option

        for( my $j = 0; $j < @keys; ++$j ) {
            my $k = $keys[$j];
            if( length $k == 1 ) {
                $k = "-$k";
            } elsif( $not ) {
                $k = "--[no-]$k";
            } else {
                $k = "--$k";
            }
            $keys[$j] = $k;
            $optw[$j] = length $k if( length $k > ( $optw[$j] // 0 ) );
        }

        # Save results for this option

        $opt = { keys => [@keys], type => $type, help => $help, opt => ( $delim eq ':' ),
                 mult => ( ref $dst eq 'ARRAY' || $mod eq '+' ) };
        push @opts, $opt;
        $flags{ $opt->{type} }[0]++;
        $flags{'*'}[0]++ if( $opt->{mult} );
    }

    # Sort options on primary keyword for display

    @opts = sort {
        my( $A, $B ) = ( $a->{keys}[0], $b->{keys}[0] );
        $A =~ s/^--\[no-\]/--/;
        $B =~ s/^--\[no-\]/--/;
        $A cmp $B;
    } @opts;

    # Generate help

    if( $cmdargs //= '' ) {
        my $pl = length( $prog ) + 1;
        $cmdargs = [ split( /\n/, $cmdargs ) ] unless( ref $cmdargs );
        for( my $i = 0; $i < @$cmdargs; ++$i ) {
            if( $i == 0 || substr( $cmdargs->[$i], 0, 1 ) eq '_' ) {
                $cmdargs->[$i] =~ s/^_?/[options] /;
            }
        }
        $cmdargs = ' ' . join( "\n" . ( ' ' x $pl ), @$cmdargs );
    }
    my $out = sprintf( "%s%s\n\nOptions:\n", $prog, $cmdargs );

    foreach my $opt ( @opts ) {
        my @keys = @{ $opt->{keys} };

        $out .= sprintf( qq(  ) );

        # Columns for this option's keywords

        for( my $k = 0; $k < @keys; ++$k ) {
            $out .= sprintf( qq(%-*s ), $optw[$k], $keys[$k] );
        }

        # Fill columns not used by this option

        for( my $f = @keys; $f < @optw; ++$f ) {
            $out .= sprintf( qq(%-*s ), $optw[$f], '' );
        }

        # Add flags / type with any padding, and help string

        $out .= sprintf( qq(%s ), $opt->{mult} ? '*' : $flags{'*'}[0] ? ' ' : '' );
        $out .= sprintf( qq(%-*s %s\n), $tw, @{$opt}{qw/type help/} );
    }

    # Add footnotes for flags (if any)

    delete $flags{''};
    my $hasflags;
    $hasflags ||= $_->[0] and last foreach( values %flags );

    if( $hasflags ) {
        $out .= sprintf( <<"HLP" );
Options marked with
HLP
        foreach my $f ( sort keys %flags ) {
            $out .= sprintf( qq(  %s %s\n), $f, $flags{$f}[1] ) if( $flags{$f}[0] );
        }
    }

    # Return or display result

    unless( defined wantarray ) {
        $fh //= \*STDOUT;
        printf $fh ( $out );
        exit( 1 );
    }
    return $out;
}

# Display man page

sub man {
    my( $fh ) = @_;

    my $str;
    if( defined wantarray ) {
        unless( defined $fh ) {
            $str = '';
            open( $fh, '>', \$str ) or croak( "open: $!\n" );
        }
    } else {
        $fh //= \*STDOUT;
    }
    eval {
        no warnings 'once';
        $Pod::Usage::Formatter = 'Pod::Text::Termcap' if( -t $fh );
        require Pod::Usage;
    } or
        croak( "Install Pod::Usage or use 'perldoc $prog'\n" );

    Pod::Usage::pod2usage( -exitval => 'NOEXIT', -output => $fh, -verbose => 2 );
    return $str if( defined $str );
    exit( 0 )   unless( defined wantarray );
    return 1;
}

# Display/return versions of caller, this module

sub version {
    my( $fh, $others );
    while( @_ && ( my $rt = reftype $_[0] ) ) {
        if( $rt eq 'GLOB' ) {
            $fh = shift;
        } elsif( $rt = 'ARRAY' ) {
            $others = shift;
        }
    }

    my %modes;
    if( ref $_[0] ) {
        %modes = %{ $_[0] };
    } else {
        foreach( @_ ) {
            my( $k, $v ) = split( /[=:]/, $_, 2 );
            $modes{$k} = $v // (   $k eq 'commit'  ? 7
                                 : $k eq 'vstring' ? 'u'
                                 :                   1 );
        }
    }

    %modes = ( withhelper => 1 ) unless( keys %modes );

    my( $str, $v ) = ( '' );
    $v = _version( scalar caller( 0 ), \%modes );
    if( defined $v ) {
        $v   = _commit( $v, \%modes );
        $str = sprintf( "Version %s", $v );
    }
    if( $modes{withdate} || !defined $v ) {
        $str = _date( $v, $str, \%modes );
    }

    $str = "Version: Unknown" unless( length $str );

    if( $modes{withhelper} ) {
        my $v = _version( __PACKAGE__ );
        $str .= sprintf( ", Helper %s", _commit( $v // 'version Unknown', \%modes ) );
        $str  = _date( $v, $str, \%modes, __PACKAGE__ );
    }
    if( $others ) {
        foreach my $mod ( @$others ) {
            my $v = _version( $mod, \%modes );
            $str .=
                sprintf( ", %s %s", $mod, _commit( $v // 'version Unknown', \%modes ) );
            $str = _date( $v, $str, \%modes, $mod );
        }
    }
    $str .= "\n";

    unless( defined wantarray ) {
        $fh //= \*STDOUT;
        printf $fh ( $str );
        exit;
    }
    return $str;
}

sub _version {
    my( $pkg, $modes ) = @_;

    no strict 'refs';
    my $v = ${"${pkg}::VERSION"};
    $v = sprintf( '%v' . ( $modes->{vstring} // 'u' ), $v ) if( isvstring( $v ) );
    return $v;
}

sub _commit {
    my( $str, $modes ) = @_;

    return $str unless( defined $str );

    my $l = length( $str );
    ;
    if( ( $l == 40 || $l == 64 ) && $str =~ /^[[:xdigit:]]{$l}$/ ) {
        $modes->{commit} //= 7;
    }

    if( ( $l = $modes->{commit} ) && $str =~ /^[[:xdigit:]]{4,64}$/ ) {

        # 40 for sha1 repos, 64 for sha256
        return sprintf( 'git-%-.*s', ( $l // 7 ), $str );
    }
    return $str;
}

sub _date {
    my( $v, $str, $modes, $pkg ) = @_;

    return $str unless( $modes->{withdate} );
    require POSIX;
    POSIX->import( qw(strftime) );

    my $file;
    if( $pkg ) {
        my $self = ( $pkg =~ s,::,/,gr ) . '.pm';
        return $str unless( $file = ( $self = $INC{$self} ) );
    } else {
        $file = "$Bin/$Script";
    }
    my $mt = ( stat $file )[9];
    if( defined $mt ) {
        my $date = strftime( '%B %d %Y %H:%M:%S', localtime( $mt ) );
        if( defined $v ) {
            $str .= sprintf( ' (%s)', $date );
        } else {
            $str = sprintf( "%sersion of %s", ( $pkg ? 'v' : 'V' ), $date );
        }
    }
    return $str;
}

1;

__END__

=pod

=head1 TL::Helper

Provide simple help for Getopt::Long

=head1 SYNOPSIS

 use Getopt::Long;
 use TL::Helper( qw/getoptions help );

 my( $help, $version );
 my @options = ( 'help|h' => \$help => 'This help', man => \$man, '',
                 version  => \$version, '' );

 GetOptions( getoptions( \@options ) ) or die( "Command error\n" );

 help( \@options ) if( $help );
 man               if( $man );
 version           if( $version );

=head1 DESCRIPTION

B<TL::Helper> provides a simple help function for Getopt::Long's options.

By including the help in the options array, maintenance is simpler than
updating POD and implemeting quick utilities can still provide help with
minimal effort.

The help text for each option is a string included as a third element
to each pair of C<switch =E<gt> target> in I<Getopt::Long>'s input array.

If no information is to be provided for an uption, specify C<undef>.

If no help is to be provided for an option, specify an empty string.

The options array's size must be an even multiple of three.

=head1 I<getoptions( $options )>

I<getoptions> takes a reference to the options array.

Normally (in array context), it returns a copy of the array with the help
strings removed, which can be used by C<Getopt::Long::GetOptions()>.

In void context, it updates the input array, rendering it useable for
C<Getopt::Long>, but useless for help.

In scalar context, it returns a reference to a copy of the array with
the help strings removed.

=head1 I<help( $options, $cmdargs, $fh )>

I<help> requires a reference to the options array.

C<$cmdargs> summarizes any non-option arguments, e.g. C<'[infile] [outfile]'>.  Omit
or use C<undef> if none.

If multiple command forms exist, separate with C\n> or provide a reference to an array.  Preceede each item after the first with C<_> if repeatingC<[options]> is desired.

In void context, it outputs help to C<$fh>, defaulting to C<STDOUT>.  It then exits.

Otherwise, it returns the help as a string.

=head1 I<man( $fh )>

I<man> provides the program's POD as a man page.

In void context, it writes to C<$fh>, or C<STDOUT>.

Otherwise, if C<$fh> is specified, it writes to C<STDOUT> and returns true.

If no C<$fh> is specified, it returns the manual as a string.

=head1 I<version( [$fh] [,\@others] [,$options | ,@options...] )>

I<version> provides the version of the caller and this module.

In void context, it outputs the version to C<$fh>, defaulting to C<STDOUT>.  It then exits.

Otherwise, it returns the version as a string.

C<@options> specifies the format of the version string.

=over 4

=item * C<withdate>

If true, includes the main script's last modified date, even if it has a C<$VERSION>.

=item * C<withhelper>

If true, includes the version of C<TL::Helper>

=item * C<commit[:$length]>

If C<$VERSION> looks like a C<git> commit id, prefix it with C<git-> and
truncate it to $length digits (default 7).  Set $length to 0 to inhibit.

=item * C<vstring:$fmt>

If C<$VERSION> is a vstring, C<$fmt> is the C<sprintf> conversion code.
Default is C<u>; other numeric codes (e.g. C<o>, C<x> can be used.

=back

The default is to only include the date if C<$VERSION> is undefined, and to
include the version of C<TL::Helper>.  If any option is specified, no
default is applied.  For just the main script's version, use C<withhelper:0>.

If a hashref is provided, the keys are the options and values should be true (1)
for boolean options or the desired value.

If an arrayref is provided, the contents are package names whose C<$VERSION>s
are alos included.  This should be limited to key dependencies.

If an option list is provided, values may be specified by appending C<:value>
to the option name.  (C<=> may be used instead of C<:>).

=head1 BUGS

Report any bugs, feature requests and/or patches to the author.

=head1 AUTHOR

Timothe Litt  E<lt>litt@acm.orgE<gt>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2025-2026 Timothe Litt

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the name of the author shall not be
used in advertising or otherwise to promote the sale, use or other dealings
in this Software without prior written authorization from the author.

Any modifications to this software must be clearly documented by and
attributed to their author, who is responsible for their effects.

Bug reports, suggestions and patches are welcomed by the original author.

=cut

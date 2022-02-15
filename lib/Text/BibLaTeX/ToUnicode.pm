use strict;
use warnings;
package Text::BibLaTeX::ToUnicode;
#ABSTRACT: Convert LaTeX commands to Unicode

=head1 SYNOPSIS

  use LaTeX::ToUnicode qw( convert );

  convert( '{\"a}'           ) eq 'ä';  # true
  convert( '"a', german => 1 ) eq 'ä';  # true, `german' package syntax
  convert( '"a',             ) eq '"a'; # not enabled by default

=head1 DESCRIPTION

This module provides a method to convert LaTeX-style markups for accents etc.
into their Unicode equivalents. It translates commands for special characters
or accents into their Unicode equivalents and removes formatting commands.

I use this module to convert values from BibTeX files into plain text, if your
use case is different, YMMV.

In contrast to L<TeX::Encode>, this module does not create HTML of any kind.

=cut

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( convert );

use utf8;
use Text::BibLaTeX::ToUnicode::Tables;

=head1 FUNCTIONS

=head2 convert( $string, %options )

Convert the text in C<$string> that contains LaTeX into a plain(er) Unicode
string. All escape sequences for special characters (e.g. \i, \"a, ...) are
converted, formatting commands (e.g. {\it ...}) are removed.

C<%options> allows you to enable additional translations. This values are
recognized:

=over

=item C<german>

If true, the commands introduced by the package `german' (e.g. C<"a> eq C<ä>,
note the missing backslash) are also handled.

=back

=cut

sub convert {
    my ( $string, %options ) = @_;
    $string = _convert_commands( $string );
    $string = _convert_accents( $string );
    $string = _convert_german( $string ) if $options{german};
    $string = _convert_symbols( $string );
    $string = _convert_specials( $string );
    $string = _convert_markups( $string );
    $string =~ s/{(\w*)}/$1/g;
    $string;
}

sub _convert_accents {
    my $string = shift;
    $string =~ s/(\{\\(.)\{(\\?\w{1,2})}})/$Text::BibLaTeX::ToUnicode::Tables::ACCENTS{$2}{$3} || $1/eg; # {\"{a}}
    $string =~ s/(\{\\(.)(\\?\w{1,2})})/$Text::BibLaTeX::ToUnicode::Tables::ACCENTS{$2}{$3} || $1/eg; # {\"a}
    $string;
}

sub _convert_specials {
    my $string = shift;
    my $specials = join( '|', @Text::BibLaTeX::ToUnicode::Tables::SPECIALS );
    my $pattern = qr/\\($specials)/o;
    $string =~ s/$pattern/$1/g;
    $string =~ s/\\\$/\$/g;
    $string;
}

sub _convert_commands {
    my $string = shift;

    foreach my $command ( keys %Text::BibLaTeX::ToUnicode::Tables::COMMANDS ) {
        $string =~ s/{\\$command}/$Text::BibLaTex::ToUnicode::Tables::COMMANDS{$command}/g;
        $string =~ s/\\$command(?=\s|\b)/$Text::BibLaTex::ToUnicode::Tables::COMMANDS{$command}/g;
    }

    $string;
}

sub _convert_german {
    my $string = shift;

    foreach my $symbol ( keys %Text::BibLaTex::ToUnicode::Tables::GERMAN ) {
        $string =~ s/\Q$symbol\E/$Text::BibLaTex::ToUnicode::Tables::GERMAN{$symbol}/g;
    }
    $string;
}

sub _convert_symbols {
    my $string = shift;

    foreach my $symbol ( keys %Text::BibLaTex::ToUnicode::Tables::SYMBOLS ) {
        $string =~ s/{\\$symbol}/$Text::BibLaTex::ToUnicode::Tables::SYMBOLS{$symbol}/g;
        $string =~ s/\\$symbol\b/$Text::BibLaTex::ToUnicode::Tables::SYMBOLS{$symbol}/g;
    }
    $string;
}

sub _convert_markups {
    my $string = shift;

    my $markups = join( '|', @Text::BibLaTex::ToUnicode::Tables::MARKUPS );
    $string =~ s/(\{[^{}]+)\\(?:$markups)\s+([^{}]+})/$1$2/g; # { ... \command ... }
    my $pattern = qr/{\\(?:$markups)\s+([^{}]*)}/o;
    $string =~ s/$pattern/$1/g;

    $string =~ s/``/“/g;
    $string =~ s/`/”/g;
    $string =~ s/''/‘/g;
    $string =~ s/'/’/g;
    $string;
}

1;

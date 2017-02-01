package Text::BibLaTeX::Author;

# ABSTRACT: Contains a single author for a BibTeX document
use warnings;
use strict;

use Text::BibLaTeX::Parser;

use overload '""' => \&to_string;

=head1 NAME

Text::BibLaTeX::Author - Contains a single author for a BibTeX document.

=cut

=head1 SYNOPSIS

This class ist a wrapper for a single BibTeX author. It is usually created
by a BibTeX::Parser.


    use Text::BibLaTeX::Author;

    my $entry = Text::BibLaTeX::Author->new($full_name);
    
    my $firstname = $author->first;
    my $von       = $author->von;
    my $last      = $author->last;
    my $jr        = $author->jr;

    # or ...
    
    my ($first, $von, $last, $jr) = BibTeX::Author->split($fullname);


=head1 FUNCTIONS

=head2 new

Create new author object. Expects full name as parameter.

=cut

sub new {
    my $class = shift;

    if (@_) {
        my $self = [ $class->split(@_) ];
        return bless $self, $class;
    }
    else {
        return bless [], $class;
    }
}

sub _get_or_set_field {
    my ( $self, $field, $value ) = @_;
    if ( defined $value ) {
        $self->[$field] = $value;
    }
    else {
        return $self->[$field];
    }
}

=head2 first

Set or get first name(s).

=cut

sub first {
    shift->_get_or_set_field( 0, @_ );
}

=head2 von

Set or get 'von' part of name.

=cut

sub von {
    shift->_get_or_set_field( 1, @_ );
}

=head2 last

Set or get last name(s).

=cut

sub last {
    shift->_get_or_set_field( 2, @_ );
}

=head2 jr

Set or get 'jr' part of name.

=cut

sub jr {
    shift->_get_or_set_field( 3, @_ );
}

=head2 split

Split name into (firstname, von part, last name, jr part). Returns array
with four strings, some of them possibly empty.

=cut

# Take a string and create an array [first, von, last, jr]
sub split {
    my ( $self_or_class, $name ) = @_;

    # remove whitespace at start and end of string
    $name =~ s/^\s*(.*)\s*$/$1/s;

    if ( !length($name) ) {
        return ( undef, undef, undef, undef );
    }

    my @comma_separated = Text::BibLaTeX::Parser::_split_braced_string( $name, '\s*,\s*' );
    if ( scalar(@comma_separated) == 0 ) {

        # Error?
        return ( undef, undef, undef, undef );
    }

    my $first = undef;
    my $von   = undef;
    my $last  = undef;
    my $jr    = undef;

    if ( scalar(@comma_separated) == 1 ) {

        # First von Last form
        my @tokens = Text::BibLaTeX::Parser::_split_braced_string( $name, '\s+' );
        if ( !scalar(@tokens) ) {
            return ( undef, undef, undef, undef );
        }
        my ( $start_von, $start_last ) = _getStartVonLast(@tokens);
        if ( $start_von > 0 ) {
            $first = join( ' ', splice( @tokens, 0, $start_von ) );
        }
        if ( ( $start_last - $start_von ) > 0 ) {
            $von = join( ' ', splice( @tokens, 0, $start_last - $start_von ) );
        }
        $last = join( ' ', @tokens );
        return ( $first, $von, $last, $jr );
    }

    # Now we work with von Last, [Jr,] First form
    if ( scalar @comma_separated == 2 ) {    # no jr
        my @tokens = Text::BibLaTeX::Parser::_split_braced_string( $comma_separated[1], '\s+' );
        $first = join( ' ', @tokens );
    }
    else {                                   # jr is present
        my @tokens = Text::BibLaTeX::Parser::_split_braced_string( $comma_separated[1], '\s+' );
        $jr = join( ' ', @tokens );
        @tokens = Text::BibLaTeX::Parser::_split_braced_string( $comma_separated[2], '\s+' );
        $first = join( ' ', @tokens );
    }
    my @tokens = Text::BibLaTeX::Parser::_split_braced_string( $comma_separated[0], '\s+' );
    my $start_last = _getStartLast(@tokens);
    if ( $start_last > 0 ) {
        $von = join( ' ', splice( @tokens, 0, $start_last ) );
    }
    $last = join( ' ', @tokens );
    return ( $first, $von, $last, $jr );

}

# Return the index of the first von element and the first lastname
# element.  If no von element, von=last

sub _getStartVonLast {
    my $length = scalar(@_);
    if ( $length == 1 ) {
        return ( 0, 0 );
    }
    my $start_von  = -1;
    my $start_last = $length - 1;
    for ( my $i = 0; $i < $length; $i++ ) {
        if ( _is_von_token( $_[$i] ) ) {
            $start_von = $i;
            last;
        }
    }
    if ( $start_von == -1 ) {    # no von part
        return ( $length - 1, $length - 1 );
    }
    if ( $start_von == $length - 1 ) {    # all parts but last are upper case?
        return ( $length - 1, $length - 1 );
    }
    for ( my $i = $start_von + 1; $i < $length; $i++ ) {
        if ( !_is_von_token( $_[$i] ) ) {
            $start_last = $i;
            last;
        }
    }
    return ( $start_von, $start_last );
}

# Return the index of the first lastname
# element provided no first name elements are present

sub _getStartLast {
    my $length = scalar(@_);
    if ( $length == 1 ) {
        return 0;
    }
    my $start_last = $length - 1;
    for ( my $i = 0; $i < $length; $i++ ) {
        if ( !_is_von_token( $_[$i] ) ) {
            $start_last = $i;
            last;
        }
    }
    return $start_last;
}

sub _split_name_parts {
    my $name = shift;

    if ( $name !~ /\{/ ) {
        return split /\s+/, $name;
    }
    else {
        my @parts;
        my $cur_token = '';
        while ( scalar( $name =~ /\G ( [^\s\{]* ) ( \s+ | \{ | \s* $ ) /xgc ) ) {
            $cur_token .= $1;
            if ( $2 =~ /\{/ ) {
                if ( scalar( $name =~ /\G([^\}]*)\}/gc ) ) {
                    $cur_token .= "{$1}";
                }
                else {
                    die "Unmatched brace in name '$name'";
                }
            }
            else {
                if ( $cur_token =~ /^{(.*)}$/ ) {
                    $cur_token = $1;
                }
                push @parts, $cur_token;
                $cur_token = '';
            }
        }
        return @parts;
    }

}

sub _get_single_author_from_tokens {
    my (@tokens) = @_;
    if ( @tokens == 0 ) {
        return ( undef, undef, undef, undef );
    }
    elsif ( @tokens == 1 ) {    # name without comma
        if ( $tokens[0] =~ /(^|\s)[[:lower:]]/ ) {    # name has von part or has only lowercase names
            my @name_parts = _split_name_parts $tokens[0];

            my $first;
            while ( @name_parts
                && ucfirst( $name_parts[0] ) eq $name_parts[0] )
            {
                $first .= $first ? ' ' . shift @name_parts : shift @name_parts;
            }

            my $von;

            # von part are lowercase words
            while ( @name_parts && lc( $name_parts[0] ) eq $name_parts[0] ) {
                $von .= $von ? ' ' . shift @name_parts : shift @name_parts;
            }

            if (@name_parts) {
                return ( $first, $von, join( " ", @name_parts ), undef );
            }
            else {
                return ( undef, undef, $tokens[0], undef );
            }
        }
        else {
            if ( $tokens[0] !~ /\{/ && $tokens[0] =~ /^((.*)\s+)?\b(\S+)$/ ) {
                return ( $2, undef, $3, undef );
            }
            else {
                my @name_parts = _split_name_parts $tokens[0];
                return ( $name_parts[0], undef, $name_parts[1], undef );
            }
        }

    }
    elsif ( @tokens == 2 ) {
        my @von_last_parts = _split_name_parts $tokens[0];
        my $von;

        # von part are lowercase words
        while ( @von_last_parts
            && lc( $von_last_parts[0] ) eq $von_last_parts[0] )
        {
            $von .= $von ? ' ' . shift @von_last_parts : shift @von_last_parts;
        }
        return ( $tokens[1], $von, join( " ", @von_last_parts ), undef );
    }
    else {
        my @von_last_parts = _split_name_parts $tokens[0];
        my $von;

        # von part are lowercase words
        while ( @von_last_parts
            && lc( $von_last_parts[0] ) eq $von_last_parts[0] )
        {
            $von .= $von ? ' ' . shift @von_last_parts : shift @von_last_parts;
        }
        return ( $tokens[2], $von, join( " ", @von_last_parts ), $tokens[1] );
    }

}

=head2 to_string( [$format] )

Return string representation of the name according to C<$format>. Format is
'FirstLast', 'LastFirst' or 'Abbreviated'. Default is 'LastFirst'.

=cut

sub to_string {
    my ( $self, $format ) = @_;
    $format = 'LastFirst' unless ($format);
    my $s = '';

    if ( $format =~ m/^firstlast/i ) {
        $s .= $self->first if ( $self->first );
        if ( $self->von ) {
            $s .= " " if ($s);
            $s .= $self->von;
        }
        $s .= " "             if ($s);
        $s .= $self->last;
        $s .= " " . $self->jr if ( $self->jr );
    }
    elsif ( $format =~ m/^abbrev/i ) {
        $s .= $self->von . " " if ( $self->von );
        $s .= $self->last;
        $s .= ", " . $self->jr if ( $self->jr );
        if ( $self->first ) {
            my $first = $self->first;
            $first =~ s/([[:upper:]])[[:lower:]]*\.?/$1./g;
            $s .= ", " . $first;
        }
    }
    elsif ( $format =~ m/^last$/i ) {
        $s .= $self->von . " "    if ( $self->von );
        $s .= $self->last;
        $s .= ", " . $self->jr    if ( $self->jr );
    }
    else {
        $s .= $self->von . " "    if ( $self->von );
        $s .= $self->last;
        $s .= ", " . $self->jr    if ( $self->jr );
        $s .= ", " . $self->first if ( $self->first );
    }
    return $s;
}

=head2 sortname

Return string as name suitable for sorting.

=cut

use locale;

sub sortname {
    my $self     = shift;
    my $sortname = $self->last;
    my $first    = $self->first;
    $sortname .= $first if ($first);
    $sortname =~ s/[-\s\.]+//g;    # remove whitespace
    return lc($sortname);
}

no locale;

# Return 1 if the first letter on brace level 0 is lowercase
sub _is_von_token {
    my $string = shift;
    while ( $string =~ s/^(\\[[:alpha:]]+\{|\{|\\[[:^alpha:]]?|[[:^alpha:]])// ) {
        if ( $1 eq '{' ) {
            my $numbraces = 1;
            while ( $numbraces != 0 && length($string) ) {
                my $symbol = substr( $string, 0, 1 );
                if ( $symbol eq '{' ) {
                    $numbraces++;
                }
                elsif ( $symbol eq '}' ) {
                    $numbraces--;
                }
                $string = substr( $string, 1 );
            }
        }
    }

    if ( length $string ) {
        my $symbol = substr( $string, 0, 1 );
        if ( lc($symbol) eq $symbol ) {
            return 1;
        }
        else {
            return 0;
        }
    }
    else {
        return 1;
    }

}

1;    # End of Text::BibLaTeX::Author

=head1 NOTES

BibTeX allows three representations of a person's name:

=over 4

=item 1.

First von Last

=item 2.

von Last, First

=item 3.

von Last, Jr, First

=back

The module always converts the first form to the second of third one
to allow simple string comparisons.  

The algorithm to determine the von part is the following: von part
consists of tokens where the first letter at brace level 0 is in lower case.
Anything in a "special characters" is on brace level 0.  Thus the following
tokens are considered von parts:  C<von>, C<\NOOP{von}Von>, and
the following token is not: C<{von}>


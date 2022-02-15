package Text::BibLaTeX::DB;

# ABSTRACT: A database approach to BibTeX files.
use warnings;
use strict;
use utf8;
use locale;

use POSIX qw(locale_h);
use Unicode::Collate::Locale;
use Text::BibLaTeX::Parser;
use IO::File;

use Data::Dumper;

=head1 NAME

Text::BibLaTeX::DB - A database-like wrapper around L<BibTeX::Parser>.

=head1 SYNOPSIS

    use Text::BibLaTeX::DB;

    my $db = Text::BibLaTeX::DB->new( "bibliography.bib" );    

=head1 FUNCTIONS

=head2 new( [$filename] )

Create a new database object linked with file C<$filename>.

=cut

our $collator;

BEGIN {
    $collator = new Unicode::Collate::Locale locale => setlocale( LC_COLLATE );
}

sub new {
    my ( $class, $file, @options ) = @_;

    my $self = bless {
        preamble => [],
        entry    => [],
        comment  => [],
        pos      => -1
    }, $class;

    $self->open($file) if ($file);

    return $self;
}

=head2 open( $filename )

Open BibTeX database C<$filename>. Returns true if file is parsed ok.

=cut

sub open {
    my ( $self, $file ) = @_;

    $self->{file} = $file if ($file);

    if ( $self->{file} && -f $self->{file} ) {
        my $fh = IO::File->new( $self->{file}, "r" );

        # ensure UTF-8 encoding
        $fh->binmode(":encoding(UTF-8)");
        my $parser = Text::BibLaTeX::Parser->new($fh);

        # parse BibTeX file
        $self->ok(1);
        while ( my $entry = $parser->next ) {
            if ( $entry->parse_ok ) {
                last unless ( $self->add($entry) );
            }
            else {
                $self->error( "Parse failed: " . $entry->error . " (line " . $parser->{line} . ")" );
                last;
            }
        }

        # close file
        $fh->close;

        # Add references to cross-referenced entries. We do this after the
        # entire file is read so the order in the BibTeX file won't matter.
        # The original BibTeX specification says that cross-referenced entries
        # must be placed before any entry that references them, but this way
        # we don't have to bother about that. If the cross-referenced item
        # does not exist, just ignore it.
        for ( my $i = 0; $i <= $#{ $self->{entry} }; $i++ ) {
            if ( $self->{entry}->[$i]->has('crossref') ) {
                my $crossref = $self->{entry}->[$i]->field('crossref');
                if ( defined $self->{index}->{$crossref} ) {
                    $self->{entry}->[$i]->_field( '_crossref', $self->{entry}->[ $self->{index}->{$crossref} ] );

                    # printf STDERR "%s (%d) cross-referenced from %s (%d)\n",
                    #     $crossref, $self->{index}->{$crossref},
                    #     $self->{entry}->[$i]->key, $i;
                }
                else {
                    print STDERR "Warning: $crossref cross-referenced from ", $self->{entry}->[$i]->key, " not found.\n";
                }
            }
        }

        return $self->ok;
    }
    $self->error("File not found");
    return $self->ok;

}

=head2 write( [$filename] )

Write the current database. If C<$filename> is specified, the database is
written to that file. Otherwise, it is written back to the file specified in
C<read()>.

=cut

sub write {
    my ( $self, $file ) = @_;

    $file = $self->{file} unless ($file);

    if ($file) {
        my $fh = IO::File->new( $file, "w" );
        $fh->binmode(":utf8");

        # write header (this is unnecessary, but avoids a bug in JabRef 3.2)
        print $fh "% Encoding: UTF-8\n\n";

        # write preambles
        foreach my $entry ( @{ $self->{preamble} } ) {
            print $fh $entry->to_string, "\n\n";
        }

        # write entries
        foreach my $entry ( @{ $self->{entry} } ) {
            print $fh $entry->to_string, "\n\n";
        }

        # write comments
        foreach my $entry ( @{ $self->{comment} } ) {
            print $fh $entry->to_string, "\n\n";
        }

        $fh->close;
        return $self->ok(1);
    }
    $self->error("No output file specified");
    return $self->ok;
}

=head2 entries()

Returns the number of regular entries in the database.

=cut

sub entries {
    my $self = shift;
    return scalar @{ $self->{entry} };
}

=head2 entry( $position )

Return entry at position C<$position> as a L<Text::BibLaTeX::Entry> object.
Returns undef if no position is specified or position is out of range.

=cut

sub entry {
    my ( $self, $position ) = @_;
    if ( defined $position ) {
        if ( $position >= 0 && $position <= $#{ $self->{entry} } ) {
            $self->{pos} = $position;
            return $self->{entry}->[$position];
        }
    }
    return undef;
}

=head2 next()

Return next entry as a L<Text::BibLaTeX::Entry> object, undef if there are no
(more) entries.

=cut

sub next {
    my $self = shift;
    return $self->entry( ++$self->{pos} );
}

=head2 pos()

Return current position in database.

=cut

sub pos {
    my $self = shift;
    return $self->{pos};
}

=head2 lookup( $key )

Lookup entry with specified key in the database.

=cut

sub lookup {
    my ( $self, $key ) = @_;
    if ( defined $self->{index}->{$key} ) {
        return $self->{entry}->[ $self->{index}->{$key} ];
    }
    return undef;
}

=head2 sort()

Sort database on author, year, title.

=cut

sub sort {
    my $self = shift;

    @{ $self->{entry} } = sort { $collator->cmp( $a->_sortkey(), $b->_sortkey() ) } @{ $self->{entry} };
    $self->{pos} = -1;
}

=head2 add( $entry )

Add L<Text::BibLaTeX::Entry> to database.

=cut

sub add {
    my ( $self, $entry ) = @_;
    if ( $entry->type eq 'COMMENT' ) {
        push @{ $self->{comment} }, $entry;
    }
    elsif ( $entry->type eq 'PREAMBLE' ) {
        push @{ $self->{preamble} }, $entry;
    }
    else {
        #print STDERR "adding normal entry ", $entry->key, "\n";
        push @{ $self->{entry} }, $entry;

        # update index of keys
        if ( !defined $self->{index}->{ $entry->key } ) {
            $self->{index}->{ $entry->key } = $#{ $self->{entry} };
        }
        else {
            $self->error( "Duplicate key " . $entry->key );
            #print STDERR "duplicate key, returing false value\n";
            return 0;
        }

        delete $self->{isbn_index} if ($self->{isbn_index});
        delete $self->{bibid_index} if ($self->{bibid_index});
    }
    return 1;
}

=head2 lookup_isbn( $isbn )

Find entry with specified isbn.

=cut

sub _build_isbn_index {
    my $self = shift;
    delete $self->{isbn_index};
    for my $i ( 0 .. $#{ $self->{entry} } ) {
        if ( $self->{entry}->[$i]->has('isbn') ) {
            my $isbn = $self->{entry}->[$i]->field('isbn');
            $isbn =~ s/[^0-9]//g;
            $self->{isbn_index}->{$isbn} = $i;
        }
    }
}

sub lookup_isbn {
    my ( $self, $isbn ) = @_;
    $self->_build_isbn_index unless ( $self->{isbn_index} );
    $isbn =~ s/[^0-9]//g;
    #print STDERR "lookup isbn=$isbn\n";
    if ( defined $self->{isbn_index}->{$isbn} ) {
        return $self->{entry}->[ $self->{isbn_index}->{$isbn} ];
    }
    return undef;
}

=head2 lookup_bibid( $bibid )

Find entry with specified LIBRIS-ID.

=cut

sub _build_bibid_index {
    my $self = shift;
    delete $self->{bibid_index};
    #print STDERR "building bibid index\n";
    for my $i ( 0 .. $#{ $self->{entry} } ) {
        if ( $self->{entry}->[$i]->has('bibid') ) {
            my $bibid = $self->{entry}->[$i]->field('bibid');
            $self->{bibid_index}->{$bibid} = $i;
#            print STDERR "$bibid -> $i\n";
        }
    }
}

sub lookup_bibid {
    my ( $self, $bibid ) = @_;
    $self->_build_bibid_index unless ( $self->{bibid_index} );
    #print STDERR "lookup bibid=$bibid\n";    
    if ( defined $self->{bibid_index}->{$bibid} ) {
        #print STDERR "bibid=$bibid found at $self->{bibid_index}->{$bibid}\n";
        return $self->{entry}->[ $self->{bibid_index}->{$bibid} ];
    }
    #print STDERR "not found\n";
    return undef;
}

=head2 ok()

If the BibTeX database was correctly read or written, this method returns a
true value, false otherwise.

=cut

sub ok {
    my $self = shift;
    if (@_) {
        $self->{ok} = shift;
    }
    return $self->{ok};
}

=head2 error()

Return the error message, if something went wrong during C<open()>.

=cut

sub error {
    my $self = shift;
    if (@_) {
        $self->{error} = shift;
        $self->ok(0);
    }
    return $self->ok ? undef : $self->{error};
}

1;

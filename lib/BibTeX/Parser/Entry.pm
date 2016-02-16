package BibTeX::Parser::Entry;

# ABSTRACT: Contains a single entry of a BibTeX document
use warnings;
use strict;

use BibTeX::Parser;
use BibTeX::Parser::Author;
use BibTeX::Parser::File;
use POSIX qw(strftime);

=head1 NAME

BibTeX::Entry - Contains a single entry of a BibTeX document.

=head1 SYNOPSIS

This class ist a wrapper for a single BibTeX entry. It is usually created
by a BibTeX::Parser.


    use BibTeX::Parser::Entry;

    my $entry = BibTeX::Parser::Entry->new($type, $key, $parse_ok, \%fields);
    
    if ($entry->parse_ok) {
        my $type    = $entry->type;
        my $key     = $enty->key;
        print $entry->field("title");
        my @authors = $entry->author;
        my @editors = $entry->editor;

        ...
    }

=cut

my %MandatoryFields = (
    ARTICLE        => [qw(author title journaltitle year/date)],
    BOOK           => [qw(author title year/date)],
    MVBOOK         => [qw(author title year/date)],
    INBOOK         => [qw(author title booktitle year/date)],
    BOOKINBOOK     => [qw(author title booktitle year/date)],
    SUPPBOOK       => [qw(author title booktitle year/date)],
    BOOKLET        => [qw(author/editor title year/date)],
    COLLECTION     => [qw(editor title year/date)],
    MVCOLLECTION   => [qw(editor title year/date)],
    INCOLLECTION   => [qw(author title booktitle year/date)],
    SUPPCOLLECTION => [qw(author title booktitle year/date)],
    MANUAL         => [qw(author/editor title year/date)],
    MISC           => [qw(author/editor title year/date)],
    ONLINE         => [qw(author/editor title year/date url)],
    PATENT         => [qw(author title number year/date)],
    PERIODICAL     => [qw(editor title year/date)],
    SUPPPERIODICAL => [qw(author title journaltitle year/date)],
    PROCEEDINGS    => [qw(title year/date)],
    MVPROCEEDINGS  => [qw(title year/date)],
    INPROCEEDINGS  => [qw(author title booktitle year/date)],
    REFERENCE      => [qw(editor title year/date)],
    MVREFERENCE    => [qw(editor title year/date)],
    INREFERENCE    => [qw(author title booktitle year/date)],
    REPORT         => [qw(author title type institution year/date)],
    SET            => [qw(entryset)],
    THESIS         => [qw(author title type institution year/date)],
    UNPUBLISHED    => [qw(author title year/date)],
    XDATA          => [qw()],
    CONFERENCE => [qw(author title booktitle year/date)],     # INPROCEEDINGS
    ELECTRONIC => [qw(author/editor title year/date url)],    # ONLINE
    MASTERSTHESIS => [qw(author title type institution year/date)],   # THESIS
    PHDTHESIS     => [qw(author title type institution year/date)],   # THESIS
    TECHREPORT    => [qw(author title type institution year/date)],   # REPORT
    WWW           => [qw(author/editor title year/date url)],         # ONLINE
);

my @Serialisation = (
    qw(author title subtitle titleaddon
        editor
        booktitle booksubtitle booktitleaddon
        maintitle mainsubtitle maintitleaddon
        journaltitle journalsubtitle issuetitle
        publisher institution location
        year date
        series volumes volume number pages
        doi url file)
);

# Inheritance for cross-referencing. This is tanken from the BibLaTeX manual,
# appendix B, "Default Inheritance Setup".

my %CrossRefKey = (
    MVBOOK => {
        INBOOK => {
            author         => 'author',
            bookauthor     => 'author',
            maintitle      => 'title',
            mainsubtitle   => 'subtitle',
            maintitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
        BOOK => {
            maintitle      => 'title',
            mainsubtitle   => 'subtitle',
            maintitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
        BOOKINBOOK => {
            author         => 'author',
            bookauthor     => 'author',
            maintitle      => 'title',
            mainsubtitle   => 'subtitle',
            maintitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
        SUPPBOOK => {
            author         => 'author',
            bookauthor     => 'author',
            maintitle      => 'title',
            mainsubtitle   => 'subtitle',
            maintitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },

    },
    MVCOLLECTION => {
        COLLECTION => {
            maintitle      => 'title',
            mainsubtitle   => 'subtitle',
            maintitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
        INCOLLECTION => {
            maintitle      => 'title',
            mainsubtitle   => 'subtitle',
            maintitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
        SUPPCOLLECTION => {
            maintitle      => 'title',
            mainsubtitle   => 'subtitle',
            maintitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
    },
    MVREFERENCE => {
        REFERENCE => {
            maintitle      => 'title',
            mainsubtitle   => 'subtitle',
            maintitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
        INREFERENCE => {
            maintitle      => 'title',
            mainsubtitle   => 'subtitle',
            maintitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
    },
    MVPROCEEDINGS => {
        PROCEEDINGS => {
            maintitle      => 'title',
            mainsubtitle   => 'subtitle',
            maintitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
        INPROCEEDINGS => {
            maintitle      => 'title',
            mainsubtitle   => 'subtitle',
            maintitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
    },
    BOOK => {
        INBOOK => {
            author         => 'author',
            bookauthor     => 'author',
            booktitle      => 'title',
            booksubtitle   => 'subtitle',
            booktitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
        BOOKINBOOK => {
            author         => 'author',
            bookauthor     => 'author',
            booktitle      => 'title',
            booksubtitle   => 'subtitle',
            booktitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
        SUPPBOOK => {
            author         => 'author',
            bookauthor     => 'author',
            booktitle      => 'title',
            booksubtitle   => 'subtitle',
            booktitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
    },
    COLLECTION => {
        INCOLLECTION => {
            booktitle      => 'title',
            booksubtitle   => 'subtitle',
            booktitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
        SUPPCOLLECTION => {
            booktitle      => 'title',
            booksubtitle   => 'subtitle',
            booktitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
    },
    REFERENCE => {
        INREFERENCE => {
            booktitle      => 'title',
            booksubtitle   => 'subtitle',
            booktitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
    },
    PROCEEDINGS => {
        INPROCEEDINGS => {
            booktitle      => 'title',
            booksubtitle   => 'subtitle',
            booktitleaddon => 'titleaddon',
            year           => 'year',
            date           => 'date',
        },
    },
    PERIODICAL => {
        ARTICLE => {
            journaltitle    => 'title',
            journalsubtitle => 'subtitle',
            year            => 'year',
            date            => 'date',
        },
        SUPPPERIODICAL => {
            journaltitle    => 'title',
            journalsubtitle => 'subtitle',
            year            => 'year',
            date            => 'date',
        },
    },
);

=head1 FUNCTIONS

=head2 new

Create new entry.

=cut

sub new {
    my ( $class, $type, $key, $parse_ok, $fieldsref ) = @_;

    my %fields = defined $fieldsref ? %$fieldsref : ();
    if ( defined $type ) {
        $fields{_type} = uc($type);
    }
    $fields{_key}      = $key;
    $fields{_parse_ok} = $parse_ok;
    $fields{_raw}      = '';
    return bless \%fields, $class;
}

=head2 parse_ok

If the entry was correctly parsed, this method returns a true value, false otherwise.

=cut

sub parse_ok {
    my $self = shift;
    if (@_) {
        $self->{_parse_ok} = shift;
    }
    $self->{_parse_ok};
}

=head2 error

Return the error message, if the entry could not be parsed or undef otherwise.

=cut

sub error {
    my $self = shift;
    if (@_) {
        $self->{_error} = shift;
        $self->parse_ok(0);
    }
    return $self->parse_ok ? undef : $self->{_error};
}

=head2 type

Get or set the type of the entry, eg. 'ARTICLE' or 'BOOK'. Return value is 
always uppercase.

=cut

sub type {
    if ( scalar @_ == 1 ) {

        # get
        my $self = shift;
        return $self->{_type};
    }
    else {
        # set
        my ( $self, $newval ) = @_;
        $self->{_type} = uc($newval);
    }
}

=head2 key

Get or set the reference key of the entry.

=cut

sub key {
    if ( scalar @_ == 1 ) {

        # get
        my $self = shift;
        return $self->{_key};
    }
    else {
        # set
        my ( $self, $newval ) = @_;
        $self->{_key} = $newval;
    }

}

=head2 field($name [, $value])

Get or set the contents of a field. The first parameter is the name of the
field, the second (optional) value is the new value.

=cut

sub _field {
    if ( scalar @_ == 2 ) {

        # get
        my ( $self, $field ) = @_;
        return $self->{ lc($field) };
    }
    else {
        my ( $self, $key, $value ) = @_;
        $self->{ lc($key) } = $value;    #_sanitize_field($value);
    }
}

sub field {
    my $self = shift;
    $self->modified(1) if ( scalar @_ > 1 );
    return $self->_field(@_);
}

=head2 resolve($name)

Get the contents of a field. If field is not found, any cross-referenced
entries are checked for that entry as well. Conversions according to BibLaTeX
with Biber applies: for example, the C<booktitle> field in a C<incollection>
entry is looked for in the C<title> field in the cross-referenced entry. See
Appendix B, "Default Inheritance Setup", in the BibLaTeX manual.

=cut

sub resolve {
    my ( $self, $key ) = @_;

    $key = lc($key);
    if ( defined $self->{$key} ) {
        return $self->{$key};
    }
    elsif ( $self->{_crossref} ) {

        # print STDERR "## resolve $key for ", $self->key, "\n";
        # print STDERR "## source type ", $self->{_crossref}->type, " (", $self->{_crossref}->key, ")\n";
        # print STDERR "## target type ", $self->type, " (", $self->key, ")\n";
        if ( $CrossRefKey{ $self->{_crossref}->type }{ $self->type }{$key} ) {

            # print STDERR "## source field ", $CrossRefKey{ $self->{_crossref}->type }{ $self->type }{$key}, "\n";
            return $self->{_crossref}
                ->{ $CrossRefKey{ $self->{_crossref}->type }{ $self->type }
                    {$key} };
        }
    }
    return undef;
}

=head2 remove( $name )

Remove field $name.

=cut

sub remove {
    my ( $self, $key ) = @_;
    delete $self->{ lc $key };
    $self->modified(1);
}

use LaTeX::ToUnicode qw( convert );

=head2 cleaned_field($name)

Retrieve the contents of a field in a format that is cleaned of TeX markup.

=cut

sub cleaned_field {
    my ( $self, $field, @options ) = @_;
    if ( $field =~ /author|editor/i ) {
        return $self->field($field);
    }
    else {
        return convert( $self->field( lc $field ), @options );
    }
}

=head2 cleaned_author

Get an array of L<BibTeX::Parser::Author> objects for the authors of this
entry. Each name has been cleaned of accents and braces.

=cut

sub cleaned_author {
    my $self = shift;
    $self->_handle_cleaned_author_editor( [ $self->author ], @_ );
}

=head2 cleaned_editor

Get an array of L<BibTeX::Parser::Author> objects for the editors of this
entry. Each name has been cleaned of accents and braces.

=cut

sub cleaned_editor {
    my $self = shift;
    $self->_handle_cleaned_author_editor( [ $self->editor ], @_ );
}

sub _handle_cleaned_author_editor {
    my ( $self, $authors, @options ) = @_;
    map {
        my $author     = $_;
        my $new_author = BibTeX::Parser::Author->new;
        map { $new_author->$_( convert( $author->$_, @options ) ) }
            grep { defined $author->$_ } qw( first von last jr );
        $new_author;
    } @$authors;
}

no LaTeX::ToUnicode;

sub _handle_author_editor {
    my $type = shift;
    my $self = shift;
    if (@_) {
        if ( @_ == 1 ) {    #single string
                            # my @names = split /\s+and\s+/i, $_[0];
            $_[0] =~ s/^\s*//;
            $_[0] =~ s/\s*$//;
            my @names
                = BibTeX::Parser::_split_braced_string( $_[0], '\s+and\s+' );
            if ( !scalar @names ) {
                $self->error('Bad names in author/editor field');
                return;
            }
            $self->{"_$type"}
                = [ map { new BibTeX::Parser::Author $_} @names ];
            $self->field( $type, join " and ", @{ $self->{"_$type"} } );
        }
        else {
            $self->{"_$type"} = [];
            foreach my $param (@_) {
                if ( ref $param eq "BibTeX::Author" ) {
                    push @{ $self->{"_$type"} }, $param;
                }
                else {
                    push @{ $self->{"_$type"} },
                        new BibTeX::Parser::Author $param;
                }

                $self->field( $type, join " and ", @{ $self->{"_$type"} } );
            }
        }
    }
    else {
        unless ( defined $self->{"_$type"} ) {
            my @names
                = BibTeX::Parser::_split_braced_string( $self->{$type} || "",
                '\s+and\s+' );
            $self->{"_$type"}
                = [ map { new BibTeX::Parser::Author $_} @names ];
        }
        return @{ $self->{"_$type"} };
    }
}

=head2 author([@authors])

Get or set the authors. Returns an array of L<BibTeX::Author|BibTeX::Author> 
objects. The parameters can either be L<BibTeX::Author|BibTeX::Author> objects
or strings.

Note: You can also change the authors with $entry->field('author', $authors_string)

=cut

sub author {
    _handle_author_editor( 'author', @_ );
}

=head2 editor([@editors])

Get or set the editors. Returns an array of L<BibTeX::Author|BibTeX::Author> 
objects. The parameters can either be L<BibTeX::Author|BibTeX::Author> objects
or strings.

Note: You can also change the authors with $entry->field('editor', $editors_string)

=cut

sub editor {
    _handle_author_editor( 'editor', @_ );
}

=head2 fieldlist()

Returns a list of all the fields used in this entry.

=cut

sub fieldlist {
    my $self = shift;

    return grep { !/^_/ } keys %$self;
}

=head2 has($fieldname)

Returns a true value if this entry has a value for $fieldname.

=cut

sub has {
    my ( $self, $field ) = @_;

    return defined $self->{$field};
}

sub _sanitize_field {
    my $value = shift;
    for ($value) {
        tr/\{\}//d;
        s/\\(?!=[ \\])//g;
        s/\\\\/\\/g;
    }
    return $value;
}

=head2 modified()

Returns true if the entry has been modified (with C<field()> above).

=cut

sub modified {
    my $self = shift;
    if (@_) {
        $self->{_modified} = shift;
    }
    $self->{_modified};

}

=head2 files()

Return an array of BibTeX::Parser::File objects.

=cut

sub files {
    my $self = shift;
    return @{ $self->_files };
}

# Return an array reference of BibTeX::Parser::File objects.

sub _files {
    my $self = shift;
    if ( $self->{_files} ) {
        return $self->{_files};
    }
    elsif ( $self->has("file") ) {
        @{ $self->{_files} }
            = map { BibTeX::Parser::File->new($_) } split m/;/,
            $self->field("file");
        return $self->{_files};
    }
    return [];
}

=head2 validate

Check internal consistency and other stuff.

=cut

sub validate {
    my $self = shift;
    my $type = $self->type;

    $self->{_validate_errors} = [];

    # check mandatory fields
    $self->{_validated} = 1;
    if ( $MandatoryFields{$type} ) {
        foreach my $fields ( @{ $MandatoryFields{$type} } ) {
            my $has_it;
            foreach my $field ( split m'/', $fields ) {
                if ( $self->resolve($field) ) {
                    $has_it = 1;
                    last;
                }
            }
            unless ($has_it) {
                push @{ $self->{_check_errors} },
                    "missing mandatory field '$fields'";
                $self->{_validated} = 0;
            }
        }
    }
    else {
        push @{ $self->{_check_errors} }, "unknown entry type '$type'";
        $self->{_validated} = 0;
    }
    return $self->{_validated};
}

=head2 validate_errors()

Return errors occured during validation.

=cut

sub validate_errors {
    my $self = shift;
    return wantarray ? @{ $self->{_check_errors} } : $self->{_check_errors};
}

=head2 raw_bibtex

Return raw BibTeX entry (if available).

=cut

sub raw_bibtex {
    my $self = shift;
    if (@_) {
        $self->{_raw} = shift;
    }
    return $self->{_raw};
}

=head2 to_string ()

Returns a text of the BibTeX entry in BibTeX format

=cut

sub to_string {
    my $self = shift;

    # for comment or preamble entries, just dump raw entry
    if ( $self->type eq 'COMMENT' || $self->type eq 'PREAMBLE' ) {
        return $self->raw_bibtex;
    }

    # make sure the 'file' field is correct before converting to_string
    if ( $self->{_files} ) {
        $self->{file}
            = join( ';', map { $_->to_string } @{ $self->{_files} } );
    }
    my @fields = grep { !/^_/ } keys %$self;

    # update timestamp if entry has been modified
    $self->_field( 'timestamp', strftime( '%Y.%m.%d', localtime ) )
        if ( $self->modified );

    # find longest field
    my $width = -1;
    for ( 0 .. $#fields ) {
        my $len = length( $fields[$_] );
        if ( $len > $width ) {
            $width = $len;
        }
    }

    # build entry from fields
    my $result = '@' . lc( $self->type ) . "{" . $self->key . ",\n";

    my %printed;    # remember which fields are printed

    # serialise fields
    foreach my $field (@Serialisation) {
        if ( $self->has($field) ) {
            $result .= sprintf( "  %-${width}s = {%s},\n",
                $field, $self->field($field) );
            $printed{$field} = 1;
        }
    }
    foreach my $field ( sort @fields ) {
        $result
            .= sprintf( "  %-${width}s = {%s},\n", $field,
            $self->field($field) )
            unless ( $printed{$field} );
    }
    $result .= "}";
    return $result;
}

# The following function creates a sort key for sorting.

sub _sortkey {
    my $self = shift;
    if ( !$self->{_sortkey} ) {

        # author or editor names
        my @names;
        if ( $self->has('author') ) {
            @names = $self->cleaned_author;
        }
        elsif ( $self->has('editor') ) {
            @names = $self->cleaned_editor;
        }
        my $name = lc( join( '', map { $_->sortname } @names ) );

        # year
        my $year;
        if ( $year = $self->resolve("date") ) {
            $year =~ s/-.*//;
        }
        else {
            $year = $self->resolve("year");
        }
        $year = "" unless ($year);

        # title
        my $title = "";
        if ( $self->has('title') ) {
            $title = lc( $self->cleaned_field('title') );
            $title =~ s/[-\s\.]+//g;    # remove whitespace
        }

        die "no title"  unless ( defined $title );
        die "no author" unless ( defined $name );
        die "no year"   unless ( defined $year );

        # create key
        $self->{_sortkey} = $name ? $name . $year . $title : $title . $year;
    }
    return $self->{_sortkey};
}

1;    # End of BibTeX::Entry

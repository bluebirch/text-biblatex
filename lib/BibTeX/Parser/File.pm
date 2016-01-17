package BibTeX::Parser::File;

# ABSTRACT: Contains a single JabRef-style file reference for a BibTeX document
use warnings;
use strict;

use overload '""' => \&to_string;

=head1 NAME

BibTeX::Parser::File - Contains a single JabRef-style file reference for a
BibTeX document

=cut

=head1 SYNOPSIS

This class is a wrapper for a single JabRef-style file reference. It is
usually created by a BibTeX::Parser.

    use BibTeX::Parser::File;

    my $entry = BibTeX::Parser::File->new($jabref_file_specification);    

=head1 FUNCTIONS

=head2 new

Create new file object. Expects JabRef style file link as parameter.

=cut

sub new {
    my ( $class, $jabref_file_string ) = @_;

    my $self = bless {}, $class;

    $self->parse($jabref_file_string) if ($jabref_file_string);

    return $self;
}

=head2 parse( $jabref_file_string )

Parse JabRef-style file link. This is a very simple format with three strings
separated by colon:

    description:path:type

In normal cases, C<parse()> is called from C<new()>.

=cut

sub parse {
    my ( $self, $jabref_file_string ) = @_;

    if ($jabref_file_string && $jabref_file_string =~ m/^[^:]*:[^:]+:[^:]+$/) {

        # Jabref store file links in three parts delimited by colon
        ( $self->{description}, $self->{path}, $self->{type} ) = split m/:/,
            $jabref_file_string;

        # Some characters can be escaped; fix that.
        $self->{path} =~ s/\\(?=&)//g;

        # JabRef on windows use backslash as separator; fix that
        $self->{path} =~ tr:\\:/:;

        return $self->{parse_ok} = 1;
    }
    return $self->{parse_ok} = undef;
}

=head2 parse_ok()

Returns true if file field was properly parsed.

=cut

sub parse_ok {
    my $self = shift;
    return $self->{parse_ok};
}

=head2 path( [$path] )

Get or set file path part of the file link.

=cut

sub path {
    my $self = shift;
    $self->{path} = shift if (@_);
    return $self->{path};
}

=head2 description( [$description] )

Get or set the description part of the file link.

=cut

sub description {
    my $self = shift;
    $self->{description} = shift if (@_);
    return $self->{description};
}

=head2 type( [$description] )

Get or set the type part of the file link.

=cut

sub type {
    my $self = shift;
    $self->{type} = shift if (@_);
    return $self->{type};
}

=head2 ext()

Get the file extention of the path, including the dot, e. g. '.pdf' for a PDF file.

=cut

sub ext {
    my $self = shift;
    if ( $self->{path} ) {
        $self->{path} =~ m/(\.\w+)$/;
        return $1;
    }
    return '';
}

=head2 exists()

Returns true if the file specified in C<path()> exists and is a regular file,
false otherwise.

=cut

sub exists {
    my $self = shift;
    return $self->{path} && -f $self->{path};

    # if ( $self->{path} ) {
    #     if ( -f $self->{path} ) {
    #         return 1;
    #     }
    #     else {
    #         return 0;
    #     }
    # }
    # print STDERR "--> no path?\n";
    # return 0;
}

=head2 rename( $new_path )

Rename file. This involves actual file operations (but not yet).

=cut

sub rename {
    my ( $self, $new_path ) = @_;

    # If file names are equal, do nothing and just return true. We DO NOT
    # rename files where only case has changed. Otherwise, this would cause
    # trouble with Mac and Windows file systems.
    if ( lc $new_path eq lc $self->{path} ) {
        return 1;
    }

    # If the currently stored path points to an existing file and the latter
    # does not, rename the former to the latter. (I guess I should add some
    # sanity controls here.)
    elsif ( $self->exists && !-f $new_path && $new_path !~ m/[!:;*"?\0]/ ) {
        if ( rename $self->{path}, $new_path ) {
            $self->path($new_path);
            return 1;

        }
    }

    # If nothing of the above applies, return undef, signifying failure. A
    # failure should also ensure that 'path' is not changed.
    return undef;
}

=head2 to_string()

Return a proper JabRef style file link.

=cut

sub to_string {
    my $self = shift;
    return join( ':', $self->{description}, $self->{path}, $self->{type} );
}

1;

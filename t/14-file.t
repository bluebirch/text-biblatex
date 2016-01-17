#!/usr/bin/perl -w

use Test::More tests => 27;

use BibTeX::Parser::File;


my $file = new BibTeX::Parser::File("description:path/to/file.pdf:PDF");

isa_ok($file, "BibTeX::Parser::File");

is($file->parse_ok, 1, "File::parse_ok valid entry");

# test description

is($file->description, "description", "File::description get");
$file->description("another description");
is($file->description, "another description", "File::description set");

# test path

is($file->path, "path/to/file.pdf", "File::path get");
$file->path("tmp");
is($file->path, "tmp", "File::path set");

# test type

is($file->type, "PDF", "File::type get");
$file->type("DOCX");
is($file->type, "DOCX", "File::type set");

# exists and rename
is( -f 'tmp', undef, "File tmp should not exist at beginning of rename." );
is( -f 'tmp2', undef, "File tmp2 should not exist at beginning of rename." );
is( $file->exists, undef, "File::exists file does not exist");
is( $file->rename( 'tmp2' ), undef, "File::rename file does not exist");
is( $file->path, "tmp", "File::path after rename & no file exists");
open TMP, ">>tmp";
close TMP;
is( -f 'tmp', 1, "File::exists file do exist" );
is( $file->rename( 'tmp2' ), 1, "File::rename file do exist");
is( -f 'tmp', undef, "File::rename old file does not exist");
is( -f 'tmp2', 1, "File::rename new file exists");
is( $file->path, "tmp2", "File::path after rename");
is( $file->exists, 1, "File::exists after rename");
is( $file->rename( ';'), undef, "File::rename invalid file name");
is( $file->path, "tmp2", "File::path after attempt to rename w/ invalid file name");
unlink "tmp2";

# to_string
is( $file->to_string, "another description:tmp2:DOCX", "File::to_string");

# test parsing of invalid file links
is( $file->parse( "path/to/file.pdf"), undef, "File::parse invalid entry");
is( $file->parse_ok, undef, "File::parse_ok invalid entry");
is( $file->parse( ":file.pdf"), undef, "File::parse invalid entry");
is( $file->parse( ":file.pdf:PDF:"), undef, "File::parse invalid entry");
is( $file->parse( ":::"), undef, "File::parse invalid entry");

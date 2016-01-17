#!/usr/bin/perl -w

use Test::More tests => 21;

use BibTeX::Parser::File;


my $file = new BibTeX::Parser::File("description:path/to/file.pdf:PDF");

isa_ok($file, "BibTeX::Parser::File");

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




# is($entry->type, "TYPE", "Entry::type get");

# $entry->type("newtype");

# is($entry->type, "NEWTYPE", "Entry::type set");

# is($entry->key, "key", "Entry::key get");

# $entry->key("newkey");

# is($entry->key, "newkey", "Entry::key set");

# is($entry->field("title"), "title", "Entry::field with new");

# $entry->field("title" => "newtitle");

# is($entry->field("title"), "newtitle", "Entry::field overwrite");

# $entry->field("year" => 2008);

# is($entry->field("year"), 2008, "Entry::field set");

# is($entry->field("pages"), undef, "Entry::field undef on unknown value");

# is($entry->fieldlist, 2, "size of fieldlist");

# ok($entry->has("title"), "Entry::has true on known value");

# ok($entry->has("year"), "Entry::has true on known value");

# ok( ! $entry->has("pages"), "Entry::has false on unknown value");

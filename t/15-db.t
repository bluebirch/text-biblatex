#!/usr/bin/perl -w

use Test::More tests => 1;

use Text::BibLaTeX::DB;

my $db = new Text::BibLaTeX::DB;

isa_ok( $db, "Text::BibLaTeX::DB" );


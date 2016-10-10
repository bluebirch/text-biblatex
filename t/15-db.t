#!/usr/bin/perl -w

use Test::More tests => 1;

use BibTeX::Parser::DB;

my $db = new BibTeX::Parser::DB;

isa_ok( $db, "BibTeX::Parser::DB" );


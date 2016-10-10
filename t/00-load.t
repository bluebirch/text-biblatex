#!/usr/bin/perl -w

use Test::More tests => 6;

BEGIN { use_ok( 'Text::BibLaTeX::Author' ); }
BEGIN { use_ok( 'Text::BibLaTeX::File' ); }
BEGIN { use_ok( 'Text::BibLaTeX::Entry' ); }
BEGIN { use_ok( 'Text::BibLaTeX::Parser' ); }
BEGIN { use_ok( 'Text::BibLaTeX::DB' ); }
BEGIN { use_ok( 'Text::BibLaTeX' ); }

#!/usr/bin/perl -w

use Test::More tests => 5;

use Text::BibLaTeX::Author;
use IO::File;

is(Text::BibLaTeX::Author::_is_von_token('von'),1);
is(Text::BibLaTeX::Author::_is_von_token('Von'),0);
is(Text::BibLaTeX::Author::_is_von_token('\noop{von}Von'),1);
is(Text::BibLaTeX::Author::_is_von_token('\noop{Von}von'),0);
is(Text::BibLaTeX::Author::_is_von_token('\noop{AE}{\AE}schylus'),0);

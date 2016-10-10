#!/usr/bin/perl -w

use Test::More tests => 12;

use Text::BibLaTeX;
use IO::File;

my @tokens = Text::BibLaTeX::Parser::_split_braced_string("a and b", '\s+and\s+');
is(scalar @tokens,2);
is($tokens[0],'a');
is($tokens[1],'b');

@tokens = Text::BibLaTeX::Parser::_split_braced_string("a {and} b", '\s+and\s+');
is(scalar @tokens,1);
is($tokens[0],'a {and} b');

@tokens = Text::BibLaTeX::Parser::_split_braced_string("a {and b", '\s+and\s+');
is(scalar @tokens,0);

@tokens = Text::BibLaTeX::Parser::_split_braced_string("} a {", '\s+');
is(scalar @tokens,0);

@tokens = Text::BibLaTeX::Parser::_split_braced_string("{a b} c {d}e   u", '\s+');
is(scalar @tokens,4);
is($tokens[0],'{a b}');
is($tokens[1],'c');
is($tokens[2],'{d}e');
is($tokens[3],'u');

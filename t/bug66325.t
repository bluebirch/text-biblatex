#!/usr/bin/perl -w

use Test::More;

use BibTeX::Parser;
use IO::File;

{
    my $fh = new IO::File "t/bibs/endnote.txt", "r" ;

    if (defined $fh) {
	    my $parser = new BibTeX::Parser $fh;

	    while (my $entry = $parser->next) {
		    diag $entry->error;
		    isa_ok($entry, "BibTeX::Parser::Entry");
		    ok($entry->parse_ok, "parse_ok");
		    is($entry->key, undef, "key");
		    is($entry->type, "ARTICLE", "type");
		    is($entry->field("year"), 1999, "field");
		    is($entry->field("volume"), 59, "first field");
	    }
    }
}

{
    my $fh = new IO::File "t/bibs/mathscinet.txt", "r" ;
    my @keys = qw(MR2254280 MR2254274 MR2248052);

    if (defined $fh) {
	    my $parser = new BibTeX::Parser $fh;
	    my $count = 0;

	    while (my $entry = $parser->next) {
		    diag $entry->error;
		    isa_ok($entry, "BibTeX::Parser::Entry");
		    ok($entry->parse_ok, "parse_ok");
		    is($entry->key, $keys[$count], "key");
		    is($entry->type, "ARTICLE", "type");
		    is($entry->field("volume"), 23, "first field");
		    is($entry->field("year"), 2006, "field");
		    $count++;
	    }

	    is($count, 3, "number of entries");
    }
}

done_testing;

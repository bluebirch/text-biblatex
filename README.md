# BibTeX::Parser

`BibTeX::Parser` is a pure Perl BibTeX parser, originally developed by Gerhard Gossen, later improved by Boris Veytsman. This fork is intended to advance `BibTeX::Parser` beyond its original scope and become a proper BibTeX library for reading *and* writing of BibTeX files, somewhat like Gergory Ward's `Text::BibTeX` but without its complexity and drawbacks (most notably proper UTF-8 support).

## BibTeX::Parser::DB

The `BibTeX::Parser::DB` package provides a somewhat 'database like' approach:

```perl
use BibTeX::Parser::DB;

my $bibdb = BibTeX::Parser::DB;
$bibdb->read($file);

while ( my $entry = $bibdb->next ) {
    ...
}

$bibdb->write;
```

On other words, `BibTeX::Parser::DB` takes care of reading and writing the BibTeX database.

Note however that this is very simple, and since `BibTeX::Parser` collapses strings and other fancy stuff in the BibTeX syntax, that is what will be written back to the BibTeX file.

## BibTeX::Parser::File

The `BibTeX::Parser::File` package is a simple way of keeping track of JabRef file link fields.

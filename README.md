# Text::BibLaTeX

`Text::BibLaTeX` is a package for handling BibLaTeX files in a database like manner. It is a fork of `BibTeX::Parser`, a pure Perl BibTeX parser originally developed by Gerhard Gossen and later improved by Boris Veytsman. In this respect, it is similar to Gergory Ward's `Text::BibTeX` but without its complexity and drawbacks (most notably proper UTF-8 support).

## Text::BibLaTeX::DB

The `Text::BibLaTeX::DB` package provides a somewhat 'database like' approach:

```perl
use Text::BibLaTeX::DB;

my $bibdb = Text::BibLaTeX::DB;
$bibdb->read($file);

while ( my $entry = $bibdb->next ) {
    ...
}

$bibdb->write;
```

On other words, `Text::BibLaTeX::DB` takes care of reading and writing the BibTeX database.

Note however that this is very simple, and since `Text::BibLaTeX::Parser` collapses strings and other fancy stuff in the BibTeX syntax, that is what will be written back to the BibTeX file.

## Text::BibLaTeX::File

The `Text::BibLaTeX::File` package is a simple way of keeping track of JabRef file link fields.

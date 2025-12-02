# Convert a path from its relative position within a resrepo

Given a path relative to the root of a resrepo (e.g.
`/data/raw/default`), it returns the full path to it. It works both on
files and directories. The first level directories can be shortened to
the first letter, so `/r/cleaning` will be expanded to
`/results/cleaning`. The same applies for the second level directories
within `/data`: `/d/r/` becomes `/data/raw/` and `/d/i/` becomes
`/data/intermediates/`

## Usage

``` r
path_resrepo(path, version = NULL, check_exists = FALSE)
```

## Arguments

- path:

  directory within a resrepo

- version:

  version of the data to use (only valid if the path starts with "/data"
  or the relevant shortcut)

- check_exists:

  boolean whether we should check if it exists

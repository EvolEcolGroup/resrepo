# Convert a path to relative

Given an absolute path, it returns the relative path with respect to a
base (by default, the working directory in R)

## Usage

``` r
path_relative(path, base = getwd())
```

## Arguments

- path:

  the full path

- base:

  optional, the base with respect to which the relative path is built.
  It defaults to the current working directory in R.

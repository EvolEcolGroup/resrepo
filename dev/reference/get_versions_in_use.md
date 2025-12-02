# Get versions of data currently in use

This returns the versions of the raw and intermediate data that are
currently in use. This is determined by the information in
"data/version_meta/raw_in_use.meta" and
"data/version_meta/intermediate_in_use.meta", which can be cross-checked
with the links in the `data` directory. This function assumes that the
current working directory is within a `resrepo` repository

## Usage

``` r
get_versions_in_use(check_links = TRUE)
```

## Arguments

- check_links:

  If TRUE, check that the links in the `data` directory are correct

## Value

A data.frame with columns, `raw` and `intermediate`, which are the
versions of the raw and intermediate data currently in use.

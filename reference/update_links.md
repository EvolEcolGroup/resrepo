# Update links to the data directories

Update links to the data directories, so that they point to the correct
version in the `versions` directory. If they links do not exist, they
will be created. If they exist, they will be updated only if the target
directory has changed.

## Usage

``` r
update_links(quiet = FALSE)
```

## Arguments

- quiet:

  if TRUE, do not print messages

## Value

TRUE if successful

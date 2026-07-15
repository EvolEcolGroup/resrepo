# Relink versions in a resrepo repository

If a repository has been cloned, relinks the "versions" directory to the
"data" directory according to the version metadata. If a user wishes to
move the "versions" directory to a different location, this function
will also update the links accordingly.

## Usage

``` r
version_relink(quiet = FALSE, resources_path = NULL)
```

## Arguments

- quiet:

  If TRUE, the user will not be prompted to backup their data. Default
  is FALSE.

- resources_path:

  The path to the directory where the "versions", the directory
  containing versioned data, will be stored. If NULL (the default),
  "versions" is placed at the root of the repository.

## Value

TRUE if the relink was successful

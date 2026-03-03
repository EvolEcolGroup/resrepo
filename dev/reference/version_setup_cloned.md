# Setup versions from a cloned repository

Setup versions from a cloned repository

## Usage

``` r
version_setup_cloned(quiet = FALSE, resources_path = NULL)
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

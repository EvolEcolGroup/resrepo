# Set up versioning for data in a resrepo for the first time

This function is used in a repository where data were being tracked and
we need to move them to a separate directory, "versions", and create
links to the data in the repository. The first version of the data is,
by default, called "initial".

## Usage

``` r
version_setup_first(quiet = FALSE, resources_path = NULL)
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

TRUE if the setup was successful

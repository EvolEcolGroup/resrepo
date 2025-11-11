# Set up versioning for data in a resrepo

Move over the data to a separate directory, "versions", and create links
to the data in the repository. The first version of the data is, by
default, called "initial". Later on, we can add further versions of the
data, using
[`version_add()`](https://evolecolgroup.github.io/resrepo/reference/version_add.md).

## Usage

``` r
version_setup(quiet = FALSE, resources_path = NULL)
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

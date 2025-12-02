# Add a version of the data directories

This function will create a new version of the data directories, by
copying the current data directories to a new directory in `versions`,
and creating links to the new directories. The new version will be
called `version_name`.

## Usage

``` r
version_add(
  path = ".",
  intermediate_new_version = NULL,
  raw_new_version = NULL,
  intermediate_source = NULL,
  raw_source = NULL,
  intermediate_description = NULL,
  raw_description = NULL,
  git_branch = NULL,
  quiet = FALSE
)
```

## Arguments

- path:

  The path to the resrepo directory

- intermediate_new_version:

  The name of the new version for the intermediate data

- raw_new_version:

  The name of the new version for the raw data. If NULL, the raw data
  will be kept in the currently used version

- intermediate_source:

  The name of the intermediate version to copy from. If NULL, it will be
  the current version

- raw_source:

  The name of the raw version to copy from. If NULL, it will be the
  current version. Ignored if `raw_new_version` is NULL.

- intermediate_description:

  A description of the new intermediate version

- raw_description:

  A description of the new raw version. Ignored if `raw_new_version` is
  NULL.

- git_branch:

  The name of the git branch to create. If NULL, it will be the same as
  `new_version`

- quiet:

  If TRUE, suppress messages

## Value

TRUE if the version was successfully added

## Details

`intermediate_new_version` and `raw_new_version` will be sanitised to
remove spaces and other characters that are not allowed in directory
names. If the sanitised version is different from the original version,
a warning will be issued.

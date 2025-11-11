# Create a symlink to a data directory in a resrepo

Create a symlink to a data directory in a resrepo (more details needed)

## Usage

``` r
data_dir_link(link_dir, target_dir)
```

## Arguments

- link_dir:

  the link, given as relative to the root of the git repository (e.g.
  "/data/raw/my_new_dir"). If the directory exists, it must be empty, as
  it will be deleted and removed.

- target_dir:

  path outside the git repository that we want to link to (i.e. where
  the data will be really stored)

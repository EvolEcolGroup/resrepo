# Track a data directory with git

This function sets up a data directory to be tracked by git. It does so
by adding the appropriate directory exception to `.gitignore`.

## Usage

``` r
data_dir_follow(path)
```

## Arguments

- path:

  the path of the data directory, given as relative to the root of the
  git repository (e.g. "/data/raw/my_new_dir")

## Value

TRUE if the directory is tracked

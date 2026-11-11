# Changelog

## resrepo (development version)

- `rmarkdown` is now imported rather than suggested:
  [`knit_to_results()`](https://evolecolgroup.github.io/resrepo/reference/knit_to_results.md)
  and
  [`create_rmd()`](https://evolecolgroup.github.io/resrepo/reference/create_rmd.md)
  need it, and failed with “there is no package called ‘rmarkdown’” when
  it was not installed.

## resrepo 0.3.1

- Fix Rmd yaml to create readme on GitHub repo

## resrepo 0.3.0

- First public release

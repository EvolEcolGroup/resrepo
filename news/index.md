# Changelog

## resrepo (development version)

- `rmarkdown` is now imported rather than suggested, as
  [`knit_to_results()`](https://evolecolgroup.github.io/resrepo/reference/knit_to_results.md)
  and
  [`create_rmd()`](https://evolecolgroup.github.io/resrepo/reference/create_rmd.md)
  need it
- [`knit_to_results()`](https://evolecolgroup.github.io/resrepo/reference/knit_to_results.md):
  fix the results folder of `.Rmd` files in subdirectories of `code/`
  given with a relative path (#62)

## resrepo 0.3.1

- Fix Rmd yaml to create readme on GitHub repo

## resrepo 0.3.0

- First public release

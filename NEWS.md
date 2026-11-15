# resrepo (development version)

* `rmarkdown` is now imported rather than suggested: `knit_to_results()` and
  `create_rmd()` need it, and failed with "there is no package called
  'rmarkdown'" when it was not installed.
* `knit_to_results()`: fix the results folder of `.Rmd` files in
  subdirectories of `code/` given with a relative path (#62)

# resrepo 0.3.1

* Fix Rmd yaml to create readme on GitHub repo

# resrepo 0.3.0

* First public release

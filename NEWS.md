# resrepo (development version)

* `rmarkdown` is now imported rather than suggested, as `knit_to_results()`
  and `create_rmd()` need it
* `knit_to_results()`: fix the results folder of `.Rmd` files in
  subdirectories of `code/` given with a relative path (#62)
* `get_versions_in_use()` and `version_add()`: fix "The link to the raw data
  is incorrect" after a `git checkout` or `git merge`

# resrepo 0.3.1

* Fix Rmd yaml to create readme on GitHub repo

# resrepo 0.3.0

* First public release

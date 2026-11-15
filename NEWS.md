# resrepo (development version)

* `rmarkdown` is now imported rather than suggested: `knit_to_results()` and
  `create_rmd()` need it, and failed with "there is no package called
  'rmarkdown'" when it was not installed.
* `knit_to_results()` now keeps the subdirectory of `code/` however the path to
  the `.Rmd` file is written: `code/analysis/test.Rmd` went to
  `results/test/` instead of `results/analysis/test/`, as did a bare file name
  knitted from within `code/analysis/`, and an absolute path whose parent
  folders included one called `code` lost the subdirectory too. The output now
  goes to the repository that holds the `.Rmd` file, which also makes it work
  when the working directory is outside that repository (#62).

# resrepo 0.3.1

* Fix Rmd yaml to create readme on GitHub repo

# resrepo 0.3.0

* First public release

# resrepo (development version)

* `rmarkdown` is now imported rather than suggested, as `knit_to_results()`
  and `create_rmd()` need it
* `knit_to_results()`: fix the results folder of `.Rmd` files in
  subdirectories of `code/` given with a relative path (#62)
* `get_versions_in_use()` and `version_add()`: fix "The link to the raw data
  is incorrect" after a `git checkout` or `git merge`
* `version_add()` checks its arguments before creating the git branch, and
  needs `raw_description` with `raw_new_version`
* `version_add()`: fix adding a version that already exists, which nested it
  inside the existing version
* `version_add()`: fix new intermediate versions also getting a copy of the
  raw data of their source version
* `path_resrepo()`: fix paths with `version`, which pointed to
  `versions/<version>/data/` instead of `versions/<version>/`
* `version_add()`: fix repositories with more than one git remote (only
  `origin` is used)
* `version_add()`: fix `ssh://` remote urls, which were not supported
* `version_add()`: fix empty https credentials when the token is in `GITHUB_PAT`
  or the remote is not on GitHub
* `version_relink()`: fix cloned repositories with a `resources_path` that
  holds `versions/`, which were linked to new, empty directories
* `knit_to_results()`: fix moving other files whose names end with the name of
  the `.Rmd` file (e.g. `notes_test.md` for `test.Rmd`)
* `knit_to_results()`: fix `.Rmd` files with a dot in their name; outputs take
  the names rmarkdown gives them (`my file.Rmd` gives `my-file.html`)
* `create_rmd()`: fix the template, which could only be knitted in RStudio
* `path_relative()`: fix paths to directories that share the start of their
  name (e.g. `abc` and `abd`), and to names with `(` or `[`
* `version_setup()` and `version_relink()`: fix the check that `resources_path`
  is not the root of the repository when run from a subdirectory
* `version_setup()` stops if the backup question is cancelled, not only if
  answered "No"
* the source of the resrepo package is also recognised, and refused, by its
  `DESCRIPTION`, not only by the name of its folder
* `version_setup()` ignores only the `versions` directory at the root (it
  ignored any directory called `versions`); `version_relink()` corrects this
* `version_add()`: fix the meta file of raw and intermediate versions with the
  same name, which kept only the raw one
* `version_add()` gains `push`: `push = FALSE` creates the version locally,
  without credentials; remotes on a local path or `http://` are now pushed to
* `version_add()` copies the data before changing anything in git, pushes
  last, and undoes its changes if it fails before the push

# resrepo 0.3.1

* Fix Rmd yaml to create readme on GitHub repo

# resrepo 0.3.0

* First public release

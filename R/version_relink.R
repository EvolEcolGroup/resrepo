

version_relink <- function(quiet = FALSE, resources_path = NULL) {
  # figure out if this repository already has data versioning
  # BUG this does not catch the case where we have just cloned a repository
  # that has version info, but we have yet to set up versioning on this
  # local copy

  if (!is.null(resources_path)) {
    # check that path do not point to root directory
    if (resources_path == ".") {
      stop("resources_path cannot be the root directory of the repository")
    } else if (normalizePath(resources_path) == normalizePath(getwd())) {
      stop("resources_path cannot be the root directory of the repository")
    }
  }
  if (!fs::file_exists(path_resrepo("data/version_meta/"))) {
    message("This resrepo repository has not been versioned. ",
            "All the data should be placed in the data folder. If you want ",
            "to version this repository, use version_setup().")
  } else {
    version_setup_cloned(quiet = quiet, resources_path = resources_path)

  }
}

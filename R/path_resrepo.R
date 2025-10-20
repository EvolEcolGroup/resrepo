#' Convert a path from its relative position within a resrepo
#'
#' Given a path relative to the root of a resrepo (e.g. `/data/raw/default`), it
#' returns the full path to it. It works both on files and directories. The
#' first level directories can be shortened to the first letter, so
#' `/r/cleaning` will be expanded to `/results/cleaning`. The same applies for
#' the second level directories withing `/data`: `/d/r/` becomes `/data/raw/`
#' and `/d/i/` becomes `/data/intermediates/`
#'
#' @param path directory within a resrepo
#' @param version version of the data to use (only valid if the path starts with
#'   "/data" or the relevant shortcut)
#' @param check_exists boolean whether we should check if it exists
#'
#' @export

path_resrepo <- function(path, version = NULL, check_exists = FALSE) {
  # first find the repo path
  git_root <- find_git_root()
  # shortcuts
  path <- sub(pattern = "^/d/", "/data/", path)
  path <- sub(pattern = "^/data/r/", "/data/raw/", path)
  path <- sub(pattern = "^/data/i/", "/data/intermediate/", path)
  path <- sub(pattern = "^/r/", "/results/", path)
  path <- sub(pattern = "^/c/", "/code/", path)
  path <- sub(pattern = "^/w/", "/writing/", path)

  # if version is specified
  if (!is.null(version)) {
    # check this version exists
    if (!version_exists(version)) {
      stop("Version ", version, " does not exist in 'versions'")
    }
    # check that path starts with data
    if (!grepl("^/data", path)) {
      stop("version can only be specified for paths starting with /data")
    }
    # remove the data prefix
    version_file_path <- stringr::str_remove(path, "^data/")
    # add the version prefix
    path <- fs::path("versions", version, version_file_path)
  }

  # add the resrepo path
  # NB. produces double backslashes
  full_path <- file.path(normalizePath(git_root), path)
  full_path <- gsub("\\\\", "/",
                    # sanitize path: convert any double backslashes
                    # to single forward slashes
                    full_path)

  # check it exists
  if (check_exists) {
    if (!any(dir.exists(full_path), file.exists(full_path))) {
      stop("path ", path, " does not exist in this repository")
    }
  }
  return(full_path)
}

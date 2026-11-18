#' Find the root of a git repository
#'
#' Returns the path of the current git repository
#'
#' The source of the resrepo package itself is refused, to avoid turning it
#' into a resrepo by mistake: a repository whose folder is called `resrepo`,
#' or whose `DESCRIPTION` file says `Package: resrepo`.
#'
#' @param path option string giving the path to use a starting point (i.e. that
#'   is part of the repository)
#'
#' @export

find_git_root <- function(path = ".") {
  root_found <- FALSE
  while (!root_found) {
    current_files <- list.files(path, all.files = TRUE)
    if (".git" %in% current_files) {
      root_found <- TRUE
      break()
    } else {
      path2 <- normalizePath(file.path(path, ".."))
      if (path2 == path) { # we have reached the root directory
        break()
      }
      path <- path2
    }
  }
  if (!root_found) {
    stop(
      "not a git repository",
      "(and none found in any of the parent directories)"
    )
  }
  # refuse to work in the source of the resrepo package itself: a repository
  # called resrepo, or one whose DESCRIPTION is that of the package (e.g. a
  # copy of the source in a folder with another name)
  desc_file <- file.path(path, "DESCRIPTION")
  is_resrepo_source <- FALSE
  if (file.exists(desc_file)) {
    desc_package <- tryCatch(
      read.dcf(desc_file, fields = "Package")[1, 1],
      error = function(e) NA_character_
    )
    is_resrepo_source <- isTRUE(desc_package == "resrepo")
  }
  if (basename(normalizePath(path)) == "resrepo" || is_resrepo_source) {
    stop(
      "You are in the source of the resrepo package (a git repository ",
      "called resrepo, or with 'Package: resrepo' in its DESCRIPTION); ",
      "this repository is reserved\n"
    )
  }
  path <- gsub("\\\\", "/", path) ## changed by Lizzie 1st Feb 2023:
  # sanitize path: convert any double backslashes to single forward slashes
  return(path)
}

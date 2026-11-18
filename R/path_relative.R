#' Convert a path to relative
#'
#' Given an absolute path, it returns the relative path with respect to a base
#' (by default, the working directory in R)
#'
#' The relative path is built by [fs::path_rel()], which compares whole
#' directory names, so that e.g. `/home/user/abd/file` relative to
#' `/home/user/abc` is `../abd/file`.
#'
#' @param path the full path
#' @param base optional, the base with respect to which the relative path is
#'   built. It defaults to the current working directory in R.
#' @returns a character string with the relative path (`"."` if `path` is
#'   `base`)
#'
#' @export

path_relative <- function(path, base = getwd()) {
  # compare the paths one directory at a time (matching the longest common
  # string of characters instead gave the wrong path for directories that
  # share the start of their name, and failed on names with characters
  # such as "(", which were read as a regular expression)
  as.character(fs::path_rel(path, start = base))
}

#' Convert a path from its relative position within a resrepo
#'
#' Given a path relative to the root of a resrepo (e.g. `/data/raw/default`), it returns
#'  the full path to it. It works both on files and directories
#'
#' @param path directory within a resrepo
#' @param check_exists boolean whether we should check if it exists
#'
#' @export

path_resrepo <- function(path, check_exists = FALSE){
  # first find the repo path
  git_root <- find_git_root()
  # add the resrepo path
  full_path <- file.path(normalizePath(git_root), path)
  # check it exists
  if (check_exists){
    if (!any(dir.exists(full_path),file.exists(full_path))){
      stop("path ", path," does not exist in this repository")
    }
  }
  return(full_path)
}

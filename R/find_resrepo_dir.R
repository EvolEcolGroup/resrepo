#' Find the path to a certain directory in a resrepo
#'
#' Given a directory of a resrepo from its root (e.g. `/data/raw/default`), it returns
#'  the full path to it
#'
#' @param directory directory within a resrepo
#'
#' @export

find_resrepo_dir <- function(directory){
  # first find the repo path
  git_root <- find_git_root()
  # add the resrepo path
  resrepo_path <- normalizePath(file.path(git_root, directory))
  # check it exists
  if (!dir.exists(resrepo_path)){
    stop("path ", directory,"does not exist in this repository")
  } else {
    return(resrepo_path)
  }
}

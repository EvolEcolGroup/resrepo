#' Untrack a data directory with git
#'
#' This function removes tracking for a data directory in git.
#'
#' @param data_path the path of the data directory, given as relative to the root
#' of the git repository (e.g. "/data/raw/my_new_dir")
#'
#' @export

data_dir_untrack <- function (path) {
  if (!dir.exists(path_resrepo(path))){
    stop("the path ", path," does not exist!")
  }
  ## TODO we shoud check that this does not already exist
  cat(paste0(resrepo_path("/.gitignore"),"\n"), append = TRUE)
}

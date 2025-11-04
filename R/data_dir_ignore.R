#' Stop tracking a data directory with git
#'
#' This function removes tracking for a data directory in git.
#'
#' @param path the path of the data directory, given as relative to the root
#' of the git repository (e.g. "/data/raw/my_new_dir")
#'
#' @keywords internal

data_dir_ignore <- function(path) {
  if (!dir.exists(path_resrepo(path))) {
    stop("the path ", path, " does not exist!")
  }
  ignore_line <- path
  my_gitignore <- readLines(path_resrepo("/.gitignore"))
  if (!ignore_line %in% my_gitignore) {
    # add a / at the end if it is not already there
    if (substr(path, nchar(path), nchar(path)) != "/") {
      path <- paste0(path, "/")
    }
    # stop and give advice if there are already tracked files
    # form this directory
    if (path %in% git2r::ls_tree()$path) {
      stop(
        "git has tracked files in this directory.",
        "To start ignoring this directory:\n",
        "1) move all the files within the directory",
        "to another temporary location\n",
        "2) commit your changes so that git will forget",
        "about those files, as it will\n",
        "   see them as deleted\n",
        "3) re-run data_dir_ingore('", path, "') in R\n",
        "4) move back your files into ", path
      )
    }
    # add it to the gitignore
    my_gitignore <- c(my_gitignore, ignore_line)
    writeLines(my_gitignore, path_resrepo("/.gitignore"))
  } else {
    warning(path, " is already being ignored by git")
  }
  return(TRUE)
}

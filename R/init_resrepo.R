#' Initialise a resrepo
#'
#' Initialise a resrepo, creating all the necessary files and directories.
#'
#' @param path optional path for the a resrepo; by defalt, we use the current
#' working directory
#'
#' @export

init_resrepo <- function (path=".") {
  git_root <- find_git_root()
  template_dir <- system.file("template",package="resrepo")
  copy_results <- file.copy(from=dir(template_dir,full.names = TRUE),
            to = git_root, recursive = TRUE, overwrite = TRUE)
  if (all(copy_results)){
    return(TRUE)
  } else {
    warning("something went wrong; not all files were included in the template")
    return(FALSE)
  }
  
}

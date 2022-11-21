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
  utils::unzip(system.file("/template/resrepo_template-main.zip", package="resrepo"),
               exdir=tempdir(), overwrite = TRUE)
  copy_results <- file.copy(from=dir(file.path(tempdir(), "resrepo_template-main"),
                     full.names = TRUE),
            to = git_root, recursive = TRUE, overwrite = TRUE)
  if (all(copy_results)){
    return(TRUE)
  } else {
    warning("something went wrong; not all files were included in the template")
    return(FALSE)
  }
  
}

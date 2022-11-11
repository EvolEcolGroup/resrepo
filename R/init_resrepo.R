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
  browser()
  utils::unzip(system.file("/template/resrepo_template-main.zip", package="resrepo"),
               exdir=tempdir(), overwrite = TRUE)
  file.copy(from=dir(file.path(tempdir(), "resrepo_template-main"),
                     full.names = TRUE),
            to = git_root, recursive = TRUE, overwrite = TRUE)
  
}

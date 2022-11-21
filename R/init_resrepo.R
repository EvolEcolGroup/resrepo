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
  template_dir <- "/home/andrea/R/x86_64-pc-linux-gnu-library/4.2/resrepo//template"
  copy_results <- file.copy(from=template_dir,
            to = git_root, recursive = TRUE, overwrite = TRUE)
  if (copy_results){
    return(TRUE)
  } else {
    warning("something went wrong; not all files were included in the template")
    return(FALSE)
  }
  
}

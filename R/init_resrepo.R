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
  copy_results <- file.copy(from=list.files(template_dir,full.names = TRUE,
                                     all.files=TRUE,no..=TRUE),
            to = git_root, recursive = TRUE, overwrite = TRUE)
  # make gitignore a hidden file
  file.rename(from = file.path(git_root,"gitignore"), 
    to = file.path(git_root,".gitignore"))
  dir.create(path_resrepo("/data/raw/original"))
  if (all(copy_results)){
    # commit initial repository (without any commits version_setup will give an error)
    git2r::add(path=".")
    git2r::commit(message="Initialise resrepo", all=TRUE)
    return(TRUE)
  } else {
    warning("something went wrong; not all files were included in the template")
    return(FALSE)
  }
}

#' Track a data directory with git
#'
#' This function sets up a data directory to be tracked by git. It does so by
#' adding the appropriate directory exception to `.gitignore`. 
#'
#' @param dir the path of the data directory, given as relative to the root
#' of the git repository (e.g. "/data/raw/my_new_dir")
#' @returns TRUE if the directory is tracked
#' @export

data_dir_follow <- function (path) {
  if (!dir.exists(path_resrepo(path))){
    stop("the path ", path," does not exist!")
  }
  ignore_line<-paste0("!",path)
  my_gitignore <- readLines(path_resrepo("/.gitignore"))
  if (!ignore_line %in% my_gitignore){
    cat(paste0(ignore_line,"\n"), file = path_resrepo("/.gitignore"), append = TRUE)
  } else {
    warning(path," is already being followed by git")
  }
  return(TRUE)
}

#' Untrack a data directory with git
#'
#' This function removes tracking for a data directory in git.
#'
#' @param path the path of the data directory, given as relative to the root
#' of the git repository (e.g. "/data/raw/my_new_dir")
#'
#' @export

data_dir_ignore <- function (path) {
  if (!dir.exists(path_resrepo(path))){
    stop("the path ", path," does not exist!")
  }
  ignore_line<-paste0("!",path)
  my_gitignore <- readLines(path_resrepo("/.gitignore"))
  if (ignore_line %in% my_gitignore){
    # stop and give advice if there are already tracked files form this directory
    dir_git2r_format <- substr(path,2, nchar(path))
    if (substr(dir_git2r_format,nchar(dir_git2r_format), nchar(dir_git2r_format))!="/"){
      dir_git2r_format <- paste0(dir_git2r_format,"/")
    }
    if (dir_git2r_format %in% git2r::ls_tree()$path){
      stop("git has tracked files in this directory. To start ignoring this directory:\n",
           "1) move all the files within the directory to another temporary location\n",
           "2) commit your changes so that git will forget about those files, as it will\n",
           "   see them as deleted\n",
           "3) re-run data_dir_ingore('",path,"') in R\n",
           "4) move back your files into ", path)
     }
    my_gitignore<-my_gitignore[!my_gitignore %in% ignore_line]
    writeLines(my_gitignore,path_resrepo("/.gitignore"))
  } else {
    warning(path," is already being ignored by git")
  }
  return(TRUE)
}

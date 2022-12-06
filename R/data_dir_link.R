#' Create a symlink to a data directory in a resrepo
#'
#' Create a symlink to a data directory in a resrepo (more details needed)
#'
#' @param link_dir the link, given as relative to the root
#' of the git repository (e.g. "/data/raw/my_new_dir")
#' @param target_dir path outside the git repository that we want to link to 
#' (i.e. where the data will be really stored)
#'
#' @export

data_dir_link <- function (link_dir, target_dir) {
  abs_data_path <- path_resrepo(link_dir)
  if(dir.exists(abs_data_path)){
    stop("the data_path ", abs_data_path," already exists!")
  }  
  if(!dir.exists(target_dir)){
    stop("the linked_path ", target_dir," does not exist!")
  }
  fs::link_create(target_dir,abs_data_path, symbolic = TRUE)
  return(TRUE)
}

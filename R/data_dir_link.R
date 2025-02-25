#' Create a symlink to a data directory in a resrepo
#'
#' Create a symlink to a data directory in a resrepo (more details needed)
#'
#' @param link_dir the link, given as relative to the root
#' of the git repository (e.g. "/data/raw/my_new_dir"). If the directory exists,
#' it must be empty, as it will be deleted and removed.
#' @param target_dir path outside the git repository that we want to link to 
#' (i.e. where the data will be really stored)
#'
#' @export

data_dir_link <- function (link_dir, target_dir) {
  # check that we have a target_dir
  if(!dir.exists(target_dir)){
    stop("the linked_path ", target_dir," does not exist!")
  }
  
  abs_data_path <- path_resrepo(link_dir)
  # if we have a directory with the same path as link_dir, remove it
  # but first make sure that it is empty
  if(dir.exists(abs_data_path)) {
    if(length(list.files(abs_data_path))!=0){
    stop("the data_dir ", abs_data_path," already exist and is not empty!/n",
         "Before creating a link, move all files to the target_dir first.")
    } else {
      unlink(abs_data_path,recursive = TRUE)
    }
  }
  fs::link_create(target_dir,abs_data_path, symbolic = TRUE)
  return(TRUE)
}

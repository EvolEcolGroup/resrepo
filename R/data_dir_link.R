#' Create a symlink to a data directory in a resrepo
#'
#' Create a symlink to a data directory in a resrepo (more details needed)
#'
#' @param data_path the path of the data directory, given as relative to the root
#' of the git repository (e.g. "/data/raw/my_new_dir")
#' @param linked_path path outside the git repository that we want to link to 
#' (i.e. where the data will really exist)
#'
#' @export

data_dir_link <- function (data_path, linked_path) {
  abs_data_path <- path_resrepo(data_path)
  if(dir.exists(abs_data_path)){
    stop("the data_path ", abs_data_path," already exists!")
  }  
  if(!dir.exists(linked_path)){
    stop("the linked_path ", linked_path," does not exist!")
  }
  fs::link_create(linked_path,abs_data_path, symbolic = TRUE)
  return(TRUE)
}

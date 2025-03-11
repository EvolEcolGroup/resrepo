#' Check that a string is a valid datadir
#'
#' Internal function to check validity of a path
#'
#' @param path string of path
#'
#' @keywords internal

is_data_dir <- function(path){
  # test that the first part is /data/
  split_by_slash <- unlist(strsplit(path,"/",fixed=TRUE))
  if(!all(length(split_by_slash), split_by_slash[1] == "",
      split_by_slash[2] == "data",
      any((split_by_slash[3] == "raw"),
        (split_by_slash[3] == "intermediate")))){
    stop(path," is not a valid data dir; it should be in the format of",
         " '/data/raw/my_dir' or '/data/intermediate/my_dir'")
  }
  return(TRUE)
  
}

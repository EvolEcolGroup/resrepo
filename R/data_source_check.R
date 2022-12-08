#' Check that data_sources are complete
#'
#' Check that all directories in /data/raw and /data/intermediate are found in data_source_list.csv,
#' and that their details are complete.
#'
#' @param path option string giving the path for the root of the repository (NOT the data
#' directory). If left NULL, then the current working directory is used.
#'
#' @export


data_source_check <- function(path=NULL){
  if (is.null(path)){
    path = getwd()
  }
  if(!file.exists(file.path(path,"./data/data_source_list.csv"))){
    stop("data_source_list.csv can not be found; are you in the root directory of your repository?")
  }
  
  data_sources <- utils::read.csv (file.path(path,"/data/data_source_list.csv"))
  # check that there are two columsn with correct names
  if (!all(c("directory","source","url") %in% names(data_sources))){
    "data_source_list.csv does not include the three mandatory columns: 'directory', 'source' and 'url'"
  }
  if (any(is.na(data_sources$source), is.na(data_sources$url))){
    stop("in data_source_list.csv, some sources/url are have been left blank; \n",
         "all entries should be filled in, use 'git' in both source and url for dirs in which files that are synchronised with git")
  }
  raw_dirs <- list.dirs(file.path(path,"data/raw"), full.names = FALSE, recursive=FALSE)
  raw_dirs <- paste0("/data/raw/",raw_dirs)
  intermediate_dirs <- list.dirs(file.path(path,"data/intermediate"), full.names = FALSE, recursive=FALSE)
  if (length(intermediate_dirs)>0){
    intermediate_dirs <- paste0("/data/intermediate/",intermediate_dirs)
  }

  if (!all(c(raw_dirs,intermediate_dirs) %in% data_sources$directory)){
    missing_dir<-
    stop("some directories are not listed in data_source_list.csv")
  }
  return(TRUE)
}

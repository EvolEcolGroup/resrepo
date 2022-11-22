#' Check that data_sources are complete
#'
#' Check that all directories in /data/raw and /data/intermediate are found in data_sources.csv,
#' and that their details are complete.
#'
#' @param path option string giving the path for the root of the repository (NOT the data
#' directory). If left NULL, then the current working directory is used.
#'
#' @export


data_sources_edit<- function(path=NULL, directory=NULL, new_directory = NULL, new_source = "NA", new_url = "NA", notes_text = "NA"){
  if (is.null(path)){
    path = getwd()
  }
  
  if(is.null(directory)){
    stop("You need to specify a directory.")
  }
  
  if(!file.exists(file.path(path,"/data/data_sources.csv"))){
    stop("data_sources.csv can not be found; are you in the root directory of your repository?")
  }
  
  original_sources <- read.csv("./data/data_sources.csv")
  
  if(!(directory %in% original_sources$directory)){
    temp_sources<-data.frame('directory' =NA, 'source' = NA, 'url' = NA, 'notes'=NA)
    temp_sources$directory<-directory
    temp_sources$source <- source
    temp_sources$url <- url
    temp_sources$notes<-notes_text
    
    new_sources<-rbind(original_sources, temp_sources)
  }
  write.csv(new_sources, "./data/data_sources.csv",row.names = FALSE)
  
  data_sources <- utils::read.csv (file.path(path,"/data/data_sources.csv"))
  # check that there are two columsn with correct names
  if (!all(c("directory","source","url") %in% names(data_sources))){
    "data_sources.csv does not include the three mandatory columns: 'directory', 'source' and 'url'"
  }
  if (any(is.na(data_sources$source), is.na(data_sources$url))){
    stop("in data_sources.csv, some sources/url are have been left blank; \n",
         "all entries should be filled in, use 'git' in both source and url for dirs in which files that are synchronised with git")
  }
  raw_dirs <- list.dirs(file.path(path,"data/raw"), full.names = FALSE, recursive=FALSE)
  raw_dirs <- paste0("/data/raw/",raw_dirs)
  intermediate_dirs <- list.dirs(file.path(path,"data/intermediate"), full.names = FALSE, recursive=FALSE)
  if (length(intermediate_dirs)>0){
    intermediate_dirs <- paste0("/data/intermediate/",intermediate_dirs)
  }
  if (!all(c(raw_dirs,intermediate_dirs) %in% data_sources$directory)){
    stop("some directories are not listed in data_sources.csv")
  }
  return(TRUE)
}

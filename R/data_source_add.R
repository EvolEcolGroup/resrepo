#' Add one entry to existing data_source_list.csv
#'
#' Checks that data_source_list exists,
#' and if so, add user_specified entry into this csv file.
#'
#' @param path option string giving the path for the root of the repository (NOT the data
#' directory). If left NULL, then the current working directory is used.
#' @param directory directory of the new entry. If directory does not exist, create it.
#' @param source source for the new entry.
#' @param url url for the new entry.
#' @param notes notes for the new entry.
#' 
#' @export


data_source_list_add<- function(path=NULL, directory=NULL, source = "NA", url = "NA", notes_text = "NA"){
  if (is.null(path)){
    path = path_resrepo("/")
  }
  
  if(is.null(directory)){
    stop("You need to specify a directory.")
  }
  
  if(!file.exists(file.path(path,"/data/data_source_list.csv"))){
    stop("data_sources.csv can not be found; are you in the root directory of your repository?")
  }
  data_source_list_find()
  
  original_sources <- read.csv(paste0(path,"/data/data_source_list.csv"))
  
  temp_sources<-data.frame('directory' =NA, 'source' = NA, 'url' = NA, 'notes'=NA)
  
  #check a directory exists or not; if not, creates it
  if(dir.exists(directory)==FALSE){
    # create output directory
    print(paste0(directory, " does not exist; create it now."))
    dir.create(file.path(directory), recursive=TRUE)
  }
  
  temp_sources$directory<-directory
  temp_sources$source <- source
  temp_sources$url <- url
  temp_sources$notes<-notes_text
  
  new_sources<-rbind(original_sources, temp_sources)
  write.csv(new_sources, paste0(path, "./data/data_source_list.csv"),row.names = FALSE)
  
  return(TRUE)
}

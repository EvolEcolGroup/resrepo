#' Add one entry to existing data_source_list.csv
#'
#' Checks that data_source_list exists,
#' and if so, add user_specified entry into this csv file.
#'
#' @param path option string giving the path for the root of the repository (NOT the data
#' directory). If left NULL, then the current working directory is used.
#' @param directory directory of the new entry. 
#' @param source source for the new entry.
#' @param url url for the new entry.
#' @param notes notes for the new entry.
#' 
#' @export


data_source_list_add<- function(path=NULL, directory=NULL, source = "NA", url = "NA", notes_text = "NA"){
  if (is.null(path)){
    path = getwd()
  }
  
  if(is.null(directory)){
    stop("You need to specify a directory.")
  }
  
  if(!data_source_list_find()){
    stop("data_source_list.csv can not be found; are you in the root directory of your repository?")
  }
  
  original_sources <- read.csv("./data/data_source_list.csv")
  
  temp_sources<-data.frame('directory' =NA, 'source' = NA, 'url' = NA, 'notes'=NA)
  temp_sources$directory<-directory
  temp_sources$source <- source
  temp_sources$url <- url
  temp_sources$notes<-notes_text
  
  new_sources<-rbind(original_sources, temp_sources)
  
  write.csv(new_sources, "./data/data_source_list.csv",row.names = FALSE)
  
  return(TRUE)
}

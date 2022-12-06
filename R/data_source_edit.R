#' Edit the data_source file
#'
#' Edit the existing lines of data_source file.
#' 
#' @param directory the directory you want to change; has to be already in the data_source.csv
#' @param path option string giving the path for the root of the repository (NOT the data
#' directory). If left NULL, then the current working directory is used.
#' @param new_directory the new directory you want to give; if NULL then does not change.
#' @param new_source the new source you want to give; if NULL then does not change.
#' @param new_url the new url you want to give; if NULL then does not change.
#' @param new_notes the new dnote you want to give; if NULL then does not change.
#' @export


data_source_edit<- function(directory, path=NULL,  new_directory = NULL, new_source = NULL, new_url = NULL , new_notes = NULL){
  if (is.null(path)){
    path = path_resrepo("/")
  }
  
  if(is.null(directory)){
    stop("You need to specify a directory.")
  }
  
  if(!file.exists(file.path(path,"/data/data_source_list.csv"))){
    stop("data_sources.csv can not be found; are you in the root directory of your repository?")
  }
  
  original_sources <- read.csv("./data/data_source_list.csv")
  new_sources_list <- original_sources
  if(!(directory %in% original_sources$directory)){
    stop(directory," is not in the data_sources list.")
  }else{
    
    if(!is.null(new_source)){
      new_sources_list$source[new_sources_list$directory==directory] <-new_source
      new_sources_list$source<-as.character(new_sources_list$source)
    }
    
    if(!is.null(new_url)){
      new_sources_list$url[new_sources_list$directory==directory] <-new_url
      new_sources_list$url<-as.character(new_sources_list$url)
    }
    
    if (!is.null(new_notes)){
      new_sources_list$notes[new_sources_list$directory==directory]<-new_notes
      new_sources_list$notes<-as.character(new_sources_list$notes)
    }
    #change directory last otherwise all changes above won't work as they cannot find the original directory!
    if(!is.null(new_directory)){
      new_sources_list$directory[new_sources_list$directory==directory] <-new_directory
      # use these to avoid bugs
      new_sources_list$directory<-as.character(new_sources_list$directory)
    }
    print(class(new_sources_list))
    
    write.csv(new_sources_list, "./data/data_source_list.csv",row.names = FALSE)
    }
  
  return(TRUE)
}

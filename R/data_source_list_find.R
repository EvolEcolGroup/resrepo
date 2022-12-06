data_source_list_find<-function(path="."){
  
  root_dir<-path_resrepo("/")
  #print(root_dir)
  if(!(file.exists(file.path(root_dir,"/data/data_source_list.csv")))){
    stop("Could not find /data/data_source_list.csv in this repository")
  }
  else{
    return(TRUE)
  }
}

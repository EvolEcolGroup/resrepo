data_source_list_find<-function(path="."){
  
  root_dir<-find_resrepo_dir("/")
  #print(root_dir)
  if(!(file.exists(file.path(root_dir,"/data/data_source_list.csv")))){
    print("Could not find /data/data_source_list.csv in this repository")
    return(FALSE)
  }
  else{
    return(TRUE)
  }
}

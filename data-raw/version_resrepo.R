



version_setup <- function(){
  git_root <- find_git_root()
  # if the version_resource path does not exist, create it
  if (!dir.exists(path_resrepo("version_resources"))){
    # create an initial version
    dir.create(path_resrepo("version_resources/initial"), recursive=TRUE)
    # copy all raw, intermediate contents
    fs::dir_copy(path_resrepo("data/raw"),path_resrepo("version_resources/initial/raw"))
    fs::dir_copy(path_resrepo("data/intermediate"),path_resrepo("version_resources/initial/intermediate"))
#    fs::dir_copy(path_resrepo("results"),path_resrepo("version_resources/initial/results"))
    # remove the old directory
    fs::dir_delete(path_resrepo("data/raw"))
    fs::dir_delete(path_resrepo("data/intermediate"))
#    fs::dir_delete(path_resrepo("results"))
    # create links
    data_dir_link(target_dir = path_resrepo("version_resources/initial/raw"),link_dir = "data/raw")
    data_dir_link(path_resrepo("version_resources/initial/intermediate"),link_dir= "data/intermediate")
#    data_dir_link(path_resrepo("version_resources/initial/results"),link_dir = "results")
    # add data_resources and data/raw and data/intermediate to gitignore
    gitignore_path <- file.path(git_root,".gitignore")
    if (!file.exists(gitignore_path)){
      file.create(gitignore_path)
    }
    writeLines(c("data_resources", "data/raw","data/intermediate"), gitignore_path)
    
  } else {
    stop("version_resources already exists")
  }
  
}




version_add <- function (path=".", new_version, source_version, description, git_branch = NULL) {
  git_root <- find_git_root()
  # check if the version_resources directory exists
  if (!dir.exists(path_resrepo("version_resources"))){
    stop("version_resources does not exist; you need to use setup_version() first")
  }
  if (is.null(git_branch)){
    git_branch <- new_version
  }
  # check that the branch does not exist on git
  if (git2r::branch_exists(git_branch)){
    stop("branch ",git_branch," already exists")
  } else {
    git2r::branch_create(git_branch)
  }
  
  # get the current version
  current_version_path <- fs::link_path(path_resrepo("data/raw"))
  current_version <- strsplit(current_version_path,"/")[[1]][length(strsplit(current_version_path,"/")[[1]])-1]
  
  # create a new version
  fs::dir_copy(path_resrepo(paste("version_resources/",current_version,sep="")),
           path_resrepo(paste("version_resources/",version_name,sep="")))
  # update the links
  # first delete the old ones
  fs::link_delete(path_resrepo("data/raw"))
  fs::link_delete(path_resrepo("data/intermediate"))
#  fs::link_delete(path_resrepo("results"))
  # then create the new ones
  data_dir_link(target_dir = path_resrepo(paste("version_resources/",version_name,"/raw",sep="")),link_dir = "data/raw")
  data_dir_link(target_dir = path_resrepo(paste("version_resources/",version_name,"/intermediate",sep="")),link_dir = "data/intermediate")
#  data_dir_link(target_dir = path_resrepo(paste("version_resources/",version_name,"/results",sep="")),link_dir = "results")
  message("new version ",version_name," created")
  # TODO add meta information on the version
  return(TRUE)
  
}
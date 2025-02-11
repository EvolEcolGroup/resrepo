#' Add a version of the data directories
#' 
#' This function will create a new version of the data directories, by copying the current
#' data directories to a new directory in `version_resources`, and creating links to the new
#' directories. The new version will be called `version_name`.
#' 
#' @param new_version The name of the new version
#' @param source_version The name of the version to copy from. If NULL, it will be the current version
#' @param description A description of the new version
#' @param git_branch The name of the git branch to create. If NULL, it will be the same as `new_version`
#' @returns TRUE if the version was successfully added


version_add <- function (path=".", new_version, source_version = NULL, description, git_branch = NULL) {
  git_root <- find_git_root()
  # check if the version_resources directory exists
  if (!dir.exists(path_resrepo("version_resources"))){
    stop("version_resources does not exist; you need to use setup_version() first")
  }
  if (is.null(git_branch)){
    git_branch <- new_version
  }
  # check that the branch does not exist on git
  if (git_branch %in%  names(git2r::branches())){
    stop("branch ",git_branch," already exists")
  } else {
    browser()
    git2r::branch_create(name = git_branch)
  }
  
  if(is.null(source_version)){
    # get the current version
    current_version_path <- fs::link_path(path_resrepo("data/raw"))
    source_version <- strsplit(current_version_path,"/")[[1]][length(strsplit(current_version_path,"/")[[1]])-1]
  }
  
  
  # create a new version
  fs::dir_copy(path_resrepo(paste("version_resources/",source_version,sep="")),
               path_resrepo(paste("version_resources/",new_version,sep="")))
  # update the links
  # first delete the old ones
  fs::link_delete(path_resrepo("data/raw"))
  fs::link_delete(path_resrepo("data/intermediate"))
  #  fs::link_delete(path_resrepo("results"))
  # then create the new ones
  data_dir_link(target_dir = path_resrepo(paste("version_resources/",new_version,"/raw",sep="")),link_dir = "data/raw")
  data_dir_link(target_dir = path_resrepo(paste("version_resources/",new_version,"/intermediate",sep="")),link_dir = "data/intermediate")
  #  data_dir_link(target_dir = path_resrepo(paste("version_resources/",version_name,"/results",sep="")),link_dir = "results")
  message("new version ",new_version," created")
  # TODO add meta information on the version
  return(TRUE)
  
}
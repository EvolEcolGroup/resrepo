#' Add a version of the data directories
#' 
#' This function will create a new version of the data directories, by copying the current
#' data directories to a new directory in `versions`, and creating links to the new
#' directories. The new version will be called `version_name`.
#' 
#' @param path The path to the resrepo directory
#' @param new_version The name of the new version
#' @param source_version The name of the version to copy from. If NULL, it will be the current version
#' @param description A description of the new version
#' @param git_branch The name of the git branch to create. 
#' If NULL, it will be the same as `new_version`
#' @param quiet If TRUE, suppress messages
#' @returns TRUE if the version was successfully added
#' @export


version_add <- function (path=".", new_version, source_version = NULL,
                         description, git_branch = NULL, quiet = FALSE) {
  # check that we have a clean working directory with git
  if (!git_is_clean()){
    stop("You have uncommitted changes; please commit or stash them ",
    "before adding a new version")
  }
  
  # check if the versions directory exists
  if (!dir.exists(path_resrepo("versions"))){
    stop("versions does not exist; you need to use setup_version() first")
  }
  # if no name for the git branch was given, use the same name as the version
  if (is.null(git_branch)){
    git_branch <- new_version
  }
  # check that the branch does not exist on git already
  if (git_branch %in%  names(git2r::branches())){
    stop("branch ",git_branch," already exists")
  } else {
    git2r::branch_create(name = git_branch)
    git2r::checkout(branch = git_branch)
  }
  
  # if no source version was given, use the current version
  if(is.null(source_version)){
    # get the current version
    current_version_path <- fs::link_path(path_resrepo("data/raw"))
    source_version <- strsplit(current_version_path,"/")[[1]][length(strsplit(current_version_path,"/")[[1]])-1]
  }
  # create a new version
  fs::dir_copy(path_resrepo(paste("versions/",source_version,sep="")),
               path_resrepo(paste("versions/",new_version,sep="")))
  # update the links
  # first delete the old ones
  fs::link_delete(path_resrepo("data/raw"))
  fs::link_delete(path_resrepo("data/intermediate"))
  #  fs::link_delete(path_resrepo("results"))
  # then create the new ones
  data_dir_link(target_dir = path_resrepo(paste("versions/",new_version,"/raw",sep="")),
                link_dir = "data/raw")
  data_dir_link(target_dir = path_resrepo(paste("versions/",new_version,"/intermediate",sep="")),
                link_dir = "data/intermediate")
  if (!quiet){
    message("version ",new_version," created")
  }
  # add meta information on the version
  version_meta <- data.frame(version = new_version, date_created = Sys.Date(), 
                             description = description, stringsAsFactors = FALSE)
  utils::write.csv(version_meta,
                   file = path_resrepo(paste0("data/version_meta/",new_version,".meta")), row.names = FALSE)
  writeLines(new_version,
             con = path_resrepo("data/version_meta/current_version_in_use_by_resrepo.meta"), sep = "\n", useBytes = FALSE)
  # add the meta files to git
  git2r::add(path=path_resrepo("data/version_meta/*"))
  git2r::commit(message = paste("Add version ",new_version), all = TRUE)
  return(TRUE)
}

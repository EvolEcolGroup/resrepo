#' Add a version of the data directories
#' 
#' This function will create a new version of the data directories, by copying the current
#' data directories to a new directory in `versions`, and creating links to the new
#' directories. The new version will be called `version_name`.
#' 
#' `intermediate_new_version` and `raw_new_version` will be sanitised to remove spaces and other characters that 
#' are not allowed in directory names. If the sanitised version is different from
#' the original version, a warning will be issued.
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


version_add <- function (path=".",
                         intermediate_new_version,
                         raw_new_version = NULL,
                         intermediate_source = NULL,
                         raw_source = NULL,
                         intermediate_description,
                         raw_description = NULL,
                         git_branch = NULL, quiet = FALSE) {
  
  in_use <- get_versions_in_use()
  
  sanitise_version <- function (x){
    x_orig <- x
    x <- fs::path_sanitize(x)
    x <- gsub(" ","_",x)
    # give a warning if the name was changed
    if (x != x_orig){
      warning(x_orig, " has been sanitised to ", x)
    }
    return(x)
  }
  
  intermediate_new_version <- sanitise_version(intermediate_new_version)
  # TODO check that this is new
  if (!is.null(raw_new_version)){
    raw_new_version <- sanitise_version(raw_new_version)
    create_raw <- TRUE
    # TODO check that this is new
  } else {
    # if null, use the current raw version
    raw_new_version <- in_use$raw
    create_raw <- FALSE
  }
  
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
    git_branch <- intermediate_new_version
  }
  # check that the branch does not exist on git already
  if (git_branch %in%  names(git2r::branches())){
    stop("branch ",git_branch," already exists")
  } else {
    git2r::branch_create(name = git_branch)
    git2r::checkout(branch = git_branch)
  }
  
  # if source versions not given, use the current one, else check that they exist
  # for raw
  if (is.null(raw_source)){
    raw_source <- in_use$raw
  } else {
    if (!dir.exists(path_resrepo(paste0("versions/",raw_source)))){
      stop("source version ",raw_source," does not exist")
    }
  }
  # same for intermediate
  if (is.null(intermediate_source)){
    intermediate_source <- in_use$intermediate
  } else {
    if (!dir.exists(path_resrepo(paste0("versions/",intermediate_source)))){
      stop("source version ",intermediate_source," does not exist")
    }
  }
  
  # create a new intermediate version
  fs::dir_copy(path_resrepo(paste("versions/",intermediate_source,sep="")),
               path_resrepo(paste("versions/",intermediate_new_version,sep="")))
  # add meta information on the version
  version_meta <- data.frame(data = "intermediate",
                             version = intermediate_new_version,
                             date_created = Sys.Date(), 
                             description = intermediate_description,
                             stringsAsFactors = FALSE)
  utils::write.csv(version_meta,
                   file = path_resrepo(paste0("data/version_meta/",intermediate_new_version,".meta")), row.names = FALSE)
  
  # if we need to create a new raw version
  if (create_raw){
    fs::dir_copy(path_resrepo(paste("versions/",raw_source,"/raw",sep="")),
                 path_resrepo(paste("versions/",raw_new_version,"/raw",sep="")))
    version_meta <- data.frame(data = "raw",
                               version = raw_new_version,
                               date_created = Sys.Date(), 
                               description = raw_description,
                               stringsAsFactors = FALSE)
    utils::write.csv(version_meta,
                     file = path_resrepo(paste0("data/version_meta/",raw_new_version,".meta")), row.names = FALSE)
    
  }
  
  # update the links
  # first delete the old ones
  fs::link_delete(path_resrepo("data/raw"))
  fs::link_delete(path_resrepo("data/intermediate"))
  #  fs::link_delete(path_resrepo("results"))
  # then create the new ones
  data_dir_link(target_dir = path_resrepo(paste("versions/",raw_new_version,"/raw",sep="")),
                link_dir = "data/raw")
  data_dir_link(target_dir = path_resrepo(paste("versions/",intermediate_new_version,"/intermediate",sep="")),
                link_dir = "data/intermediate")
  if (!quiet){
    message("version ",intermediate_new_version," created")
    if(create_raw){
      message("raw version ",raw_new_version," created")
    }
  }
  utils::write.csv(data.frame( raw = raw_new_version, intermediate = intermediate_new_version),
                   file = path_resrepo("data/version_meta/in_use.meta"),
                   row.names = FALSE
  )  # add the meta files to git
  git2r::add(path=path_resrepo("data/version_meta/*"))
  commit_message <- paste("Add version",intermediate_new_version)
  if (create_raw){
    commit_message <- paste(commit_message, "and", raw_new_version)
  }
  git2r::commit(message = commit_message, all = TRUE)
  return(TRUE)
}

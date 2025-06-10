#' Add a version of the data directories
#'
#' This function will create a new version of the data directories, by copying
#' the current data directories to a new directory in `versions`, and creating
#' links to the new directories. The new version will be called `version_name`.
#'
#' `intermediate_new_version` and `raw_new_version` will be sanitised to remove
#' spaces and other characters that are not allowed in directory names. If the
#' sanitised version is different from the original version, a warning will be
#' issued.
#'
#' @param path The path to the resrepo directory
#' @param intermediate_new_version The name of the new version for the
#'   intermediate data
#' @param raw_new_version The name of the new version for the raw data. If NULL,
#'   the raw data will be kept in the currently used version
#' @param intermediate_source The name of the intermediate version to
#'   copy from. If NULL, it will be the current version
#' @param raw_source The name of the raw version to copy from. If NULL,
#'   it will be the current version. Ingored if `raw_new_version` is NULL.
#' @param intermediate_description A description of the new intermediate version
#' @param raw_description A description of the new raw version. Ignored if
#'  `raw_new_version` is NULL.
#' @param git_branch The name of the git branch to create. If NULL, it will be
#'   the same as `new_version`
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
  # check for git credentials 
  creds <- get_resrepo_git_creds()
  
  # check version in use
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
    if (creds$type == "ssh" || creds$type == "https"){
      git2r::push(name = "origin",
                  refspec = paste0("refs/heads/", git_branch),
                  set_upstream = TRUE, 
                  credentials = creds$github_pat)
    }
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
  # write the versions to file
  writeLines(raw_new_version,
             con = path_resrepo("data/version_meta/raw_in_use.meta"),
             sep = "\n", useBytes = FALSE)
  writeLines(intermediate_new_version,
             con = path_resrepo("data/version_meta/intermediate_in_use.meta"),
             sep = "\n", useBytes = FALSE)
  # add the meta files to git
  git2r::add(path=path_resrepo("data/version_meta/*"))
  commit_message <- paste("Add version",intermediate_new_version)
  if (create_raw){
    commit_message <- paste(commit_message, "and", raw_new_version)
  }
  git2r::commit(message = commit_message, all = TRUE)
    if (creds$type == "ssh" || creds$type == "https"){
      git2r::push(name = "origin",
                  refspec = paste0("refs/heads/", git_branch),
                  credentials = creds$github_pat)
    }
  return(TRUE)
}

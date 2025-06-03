#' Get git credentials if they are available
#' 
#' This function checks the current git remote URL and determines if the 
#' credentials are set up for SSH or HTTPS access.
#' @return A list containing the type of credentials, the URL, and the
#' GitHub PAT if applicable.
#' @keywords internal

get_resrepo_git_creds <- function(){
  # figure out if we are using ssh or https
  git_url <- git2r::remote_url()
  # @TODO is this correct?????
  if (git_url == ""){
    creds <- list(
      type = "none",
      url = NULL,
      github_pat = NULL
    )
  }
  git_url <- system("git config --get remote.origin.url", intern = TRUE)
  if (grepl("^git@", git_url)) {
    # SSH URL
    creds <- list(
      type = "ssh",
      url = git_url,
      github_pat = NULL # pat is null as we are using ssh
    )
  } else if (grepl("^https://", git_url)) {
    # copy to the PAT to an env variable
    # catch the error if we don't have one
    tryCatch(
      git_host <- gitcreds::gitcreds_get()$host,
      error = function(e) {
        stop("You don't have a PAT set up with `gitcreds`. Please set it using gitcreds::gitcreds_set().")
      }
    )
    git_env_var <- gitcreds::gitcreds_cache_envvar(url = git_host)
    
    # HTTPS URL
    creds <- list(
      type = "https",
      url = git_url,
      github_pat = Sys.getenv(git_env_var)
    )
  } else {
    stop("Unsupported Git URL format.")
  }
  return(creds)
}
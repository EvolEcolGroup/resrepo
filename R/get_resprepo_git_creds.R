#' Get git credentials if they are available
#'
#' This function checks the URL of the `origin` remote (the one resrepo pushes
#' to) and determines if the credentials are set up for SSH or HTTPS access.
#' Without an `origin` remote, the type is "none".
#' @return A list containing the type of credentials, the URL, and the
#' GitHub PAT if applicable.
#' @keywords internal

get_resrepo_git_creds <- function() {
  # figure out if we are using ssh or https; resrepo pushes to "origin", so
  # only the url of that remote matters (git2r::remote_url() without a remote
  # returns one url per remote)
  if ("origin" %in% git2r::remotes()) {
    git_url <- git2r::remote_url(remote = "origin")
  } else {
    git_url <- character(0)
  }
  # without an origin there is nothing to push to
  if (length(git_url) == 0) {
    creds <- list(
      type = "none",
      url = NULL,
      github_pat = NULL
    )
    return(creds)
  }
  if (grepl("^git@", git_url) || grepl("^ssh://", git_url)) {
    # SSH URL, either scp-like (git@host:path) or with the ssh:// scheme
    creds <- list(
      type = "ssh",
      url = git_url,
      github_pat = NULL # pat is null as we are using ssh
    )
  } else if (grepl("^https://", git_url)) {
    # get the PAT for the host of the remote (which is not always
    # github.com); gitcreds finds it in the git credential store or in env
    # variables such as GITHUB_PAT
    # catch the error if we don't have one
    git_creds <- tryCatch(
      gitcreds::gitcreds_get(url = git_url),
      error = function(e) {
        stop(
          "You don't have a PAT set up with `gitcreds`. ",
          "Please set it using gitcreds::gitcreds_set()."
        )
      }
    )
    # a token given on its own (e.g. in GITHUB_PAT) has no username; the
    # hosts accept any username with a token
    username <- git_creds$username
    if (is.null(username) || is.na(username) || !nzchar(username)) {
      username <- "PersonalAccessToken"
    }

    # HTTPS URL
    creds <- list(
      type = "https",
      url = git_url,
      github_pat = git2r::cred_user_pass(
        username = username,
        password = git_creds$password
      )
    )
  } else {
    stop("Unsupported Git URL format.")
  }
  return(creds)
}

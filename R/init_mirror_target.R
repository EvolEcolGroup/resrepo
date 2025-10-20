#' Initialise a resrepo
#'
#' Initialise a resrepo, creating all the necessary files and directories.
#'
#' @param path optional path for the a resrepo; by defalt, we use the current
#' working directory
#'
#' @export

init_mirror <- function(path) {
  if (is.null(path) || !dir.exists(path)) {
    stop("path needs to be a valid path")
  }
  project_name <- basename(normalizePath(find_git_root()))
  mirror_path <- file.path(path, project_name)
  # if it does not exist, create it
  if (!dir.exists(mirror_path)) {
    dir.create(mirror_path)
  } else {
    if (length(list.files(mirror_path) != 0)) {
      stop("the mirror directory ", mirror_path, " already exists and contains
           files!")
    }
  }
  template_dir <- system.file("template_mirror", package = "resrepo")
  copy_results <- file.copy(
    from = list.files(template_dir,
      full.names = TRUE,
      all.files = TRUE, no.. = TRUE
    ),
    to = mirror_path, recursive = TRUE, overwrite = TRUE
  )
  if (all(copy_results)) {
    message(
      "the mirror directory for project ",
      project_name, " was initialised in\n",
      mirror_path
    )
    return(TRUE)
  } else {
    warning(paste0(
      "something went wrong; ",
      " not all files were included in the template"
    ))
    return(FALSE)
  }
}

#' Edit the data_source file
#'
#' Edit the existing lines of data_source file.
#'
#' @param dir directory of the entry to edit. It should be given relative to the
#'   root of the git repository. If the directory does not exist, it will be
#'   created.
#' @param source source for the new entry (e.g. zenodo, onedrive, dropbox,
#'   etc.).
#' @param url url for the source.
#' @param notes notes for the new entry.
#' @param git_path option string giving the path for the root of the repository
#'   (NOT the data directory). If left NULL, then the current working directory
#'   is used.
#' @returns TRUE if successful
#' @export


data_source_edit <- function(dir = NULL, source = NA, url = NA,
                             notes = NA, git_path = NULL) {
  if (is.null(dir)) {
    stop("You need to specify a directory.")
  }
  is_data_dir(dir)

  if (is.null(git_path)) {
    git_path <- find_git_root()
  }

  if (!file.exists(file.path(git_path, "/data/data_source_list.csv"))) {
    stop(
      "data_sources_list.csv can not be found;\n",
      "are you in the root directory of your repository?"
    )
  }

  original_sources <- utils::read.csv(path_resrepo(
    "/data/data_source_list.csv"
  ))
  if (!dir %in% original_sources$directory) {
    stop(
      dir, " does not exist in data_source_list.csv;\n",
      "use 'data_source_add' to add an entry."
    )
  }

  new_sources_list <- original_sources

  if (!is.null(source)) {
    new_sources_list$source[new_sources_list$directory == dir] <- source
    new_sources_list$source <- as.character(new_sources_list$source)
  }

  if (!is.null(url)) {
    new_sources_list$url[new_sources_list$directory == dir] <- url
    new_sources_list$url <- as.character(new_sources_list$url)
  }

  if (!is.null(notes)) {
    new_sources_list$notes[new_sources_list$directory == dir] <- notes
    new_sources_list$notes <- as.character(new_sources_list$notes)
  }

  utils::write.csv(new_sources_list,
    path_resrepo("/data/data_source_list.csv"),
    row.names = FALSE
  )

  return(TRUE)
}

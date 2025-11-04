#' Add a new data source
#'
#' This function adds a data source to the data_source_list.csv file. If the
#' directory does not exist yet, it will create one.
#'
#' @param dir directory of the new entry. It should be given relative to the
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


data_source_add <- function(dir = NULL, source = NA, url = NA,
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

  original_sources <- utils::read.csv(
    path_resrepo("/data/data_source_list.csv")
  )
  if (dir %in% original_sources$directory) {
    stop(
      dir, " already exists in data_source_list.csv;\n",
      "use 'data_source_edit' to edit an entry."
    )
  }

  temp_sources <- data.frame(
    "directory" = NA, "source" = NA,
    "url" = NA, "notes" = NA
  )

  # check a directory exists or not; if not, creates it
  if (!dir.exists(path_resrepo(dir))) {
    # create output directory
    message(dir, " does not exist; create it now.")
    dir.create(path_resrepo(dir))
  }

  temp_sources$directory <- dir
  temp_sources$source <- source
  temp_sources$url <- url
  temp_sources$notes <- notes

  new_sources <- rbind(original_sources, temp_sources)
  utils::write.csv(new_sources,
    path_resrepo("./data/data_source_list.csv"),
    row.names = FALSE
  )

  return(TRUE)
}

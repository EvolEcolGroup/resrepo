#' Create a new Rmarkdown file from the template
#'
#' Creates and writes to file a new Rmarkdown (.Rmd) file from the \code{resrepo}
#'  template. The YAML header contains the \code{knit_to_results} function,
#'  and the template includes code chunks for setting input and output
#'  directories using resrepo functions.
#'
#' @param filename file path to new Rmd file to be created, excluding file
#'  extension. Can be in a subfolder, e.g. \code{"code/s01_process_data"}
#'
#' @export
#' 
create_rmd <- function(filename){
  rmarkdown::draft(file = filename, template = "resrepo-rmd-template", package = "resrepo", create_dir = "default", edit = FALSE)
}
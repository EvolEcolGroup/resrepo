#' Knit RMarkdown file to results folder
#'
#' This function is used in the YAML of an RMarkdown file so that when it is 
#' knitted, the output file is sent to the \code{~/results} directory rather than 
#' the directory in which the \code{.Rmd} file is located.
#' The output file can be \code{.pdf}, \code{.html}, \code{.md} etc.
#' NB. This function does NOT cause any objects that are written to file in
#' your \code{.Rmd} code to be written to the new results directory by default. 
#' To ensure all objects are written to the correct directories, specify an
#' \code{output_dir} directly in the code.
#'
#' @param inputFile The name of the R Markdown file to be rendered.
#' @param encoding This is ignored. The encoding is always assumed to be UTF-8.
#'
#' @export

knit_to_results <- function(inputFile, encoding) {
  
  ## check that the last 4 letters of inputFile are '.Rmd'
  if (tolower(substr(base::basename(inputFile), (nchar(base::basename(inputFile)) - 3), nchar(base::basename(inputFile)))) != ".rmd") {
    stop("Attempting to use knit_to_results on a file that is not a .Rmd or .rmd file.")
  }
  
  ## get the filename from inputFile
  fname <- paste0(substr(base::basename(inputFile), 1, nchar(base::basename(inputFile)) - 4))

  ## run the rmarkdown render function
  rmarkdown::render(
    input = inputFile,
    encoding = encoding,
    output_dir = file.path(path_relative(path_resrepo("results")), fname),  # put into a new folder under results
    output_file = fname  # file name is the same as the folder name
  )
}
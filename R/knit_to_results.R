#' Custom knit function for RStudio
#'
#' This function is used in the YAML of an RMarkdown file so that when it is 
#' knitted, the output \code{.md} file (and associated image files) are sent to 
#' the \code{~/results} folder rather than the folder in which the \code{.Rmd} 
#' file is located.
#'
#' @param inputFile The name of the R Markdown file to be rendered.
#' @param encoding As per \code{rmarkdown::render_site()} this is ignored.
#' The encoding is always assumed to be UTF-8.
#'
#' @export

knit_to_results <- function(inputFile, encoding) {
  ## get the filename from YAML params - REMOVED FOR NOW
  # fname <- rmarkdown::yaml_front_matter(inputFile)$params$output_filename
  ## run the rmarkdown render function
  rmarkdown::render(
    input       = inputFile,
    encoding    = encoding,
    output_dir  = "../results",
    # remove .Rmd from input file and use that as output file name
    output_file = paste0(substr(inputFile, 1, nchar(inputFile) - 4))
  )
}
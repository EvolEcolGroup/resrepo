#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

# dummy function to avoid R CMD check NOTE about renv
dummy_renv <- function() {
  renv::activate()
}

# dummy function to avoid R CMD check NOTE about studioapi
dummy_studioapi <- function() {
  rstudioapi::getActiveProject()
}

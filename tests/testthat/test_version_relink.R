

test_that("version_relink works correctly", {
  example_dir <- file.path(tempdir(), "resrepo_example")
  unlink(example_dir, recursive = TRUE)
  dir.create(example_dir, showWarnings = FALSE)
  
  # create a subdirectory of example_dir
  sub_dir <- file.path(example_dir, "subdir")
  dir.create(sub_dir, showWarnings = FALSE)
  
  example_repo <- git2r::init(sub_dir, branch = "main")
  git2r::config(example_repo, user.name = "Test", user.email = "test@example.org")
  # set our working directory in the git repository
  setwd(sub_dir)
  
  init_resrepo()
  
  file.copy(
    from = system.file("vignette_example/tux_measurements.csv",
                       package = "resrepo"
    ),
    to = path_resrepo("/data/raw/original/tux_measurements.csv"),
    overwrite = TRUE
  )
  file.copy(
    from = system.file("vignette_example/s01_download_penguins.Rmd",
                       package = "resrepo"
    ),
    to = path_resrepo("/code/s01_download_penguins.Rmd"),
    overwrite = TRUE
  )
  knit_to_results(path_resrepo("/code/s01_download_penguins.Rmd"))
  file.copy(
    from = system.file("vignette_example/s02_merge_clean.Rmd",
                       package = "resrepo"
    ),
    to = path_resrepo("/code/s02_merge_clean.Rmd"),
    overwrite = TRUE
  )
  knit_to_results(path_resrepo("/code/s02_merge_clean.Rmd"))
  file.copy(
    from = system.file("vignette_example/s03_pca.Rmd", package = "resrepo"),
    to = path_resrepo("/code/s03_pca.Rmd"),
    overwrite = TRUE
  )
  knit_to_results(path_resrepo("/code/s03_pca.Rmd"))
  git2r::add(path = ".")
  git2r::commit(message = "Set up", all = TRUE)
  
  
version_setup(quiet = TRUE, resources_path = NULL)


# create new data directory where we want to move our data
new_data_dir <- file.path(example_dir, "new_data_dir")
dir.create(new_data_dir, showWarnings = FALSE)

# move versions folder to new_data_dir
file.rename(
  from = path_resrepo("versions"),
  to = file.path(new_data_dir, "versions")
)

# relink the version
version_relink(quiet = TRUE, resources_path = new_data_dir)

expect_true(version_add(
  intermediate_new_version = "new_filtering",
  intermediate_description = "Filtering out some data"
))

#TODO: add more tests here to check that the relinking worked correctly
})


#TODO handle case moving versions from one external data location to another 

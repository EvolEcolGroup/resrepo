test_that("version_relink works correctly", {
  example_dir <- file.path(tempdir(), "resrepo_example")
  if (dir.exists(example_dir)) {
    fs::dir_delete(example_dir)
  }
  dir.create(example_dir, showWarnings = FALSE)

  # create a subdirectory of example_dir
  sub_dir <- file.path(example_dir, "subdir")
  dir.create(sub_dir, showWarnings = FALSE)

  example_repo <- git2r::init(sub_dir, branch = "main")
  git2r::config(example_repo,
    user.name = "Test",
    user.email = "test@example.org"
  )
  # set our working directory in the git repository
  withr::local_dir(as.character(sub_dir))

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
  # silence knitr
  suppressMessages(
    capture.output(
      knit_to_results(path_resrepo("/code/s01_download_penguins.Rmd"))
    )
  )
  file.copy(
    from = system.file("vignette_example/s02_merge_clean.Rmd",
      package = "resrepo"
    ),
    to = path_resrepo("/code/s02_merge_clean.Rmd"),
    overwrite = TRUE
  )
  # silence knitr
  suppressMessages(
    capture.output(knit_to_results(path_resrepo("/code/s02_merge_clean.Rmd")))
  )
  file.copy(
    from = system.file("vignette_example/s03_pca.Rmd", package = "resrepo"),
    to = path_resrepo("/code/s03_pca.Rmd"),
    overwrite = TRUE
  )
  # silence knitr
  suppressMessages(
    capture.output(knit_to_results(path_resrepo("/code/s03_pca.Rmd")))
  )
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
  version_relink(
    quiet = TRUE, resources_path = new_data_dir
  )

  expect_true(version_add(
    intermediate_new_version = "new_filtering",
    intermediate_description = "Filtering out some data",
    quiet = TRUE
  ))

  # TODO: add more tests here to check that the relinking worked correctly
})

test_that("move versions from one external data location to another", {
  example_dir <- file.path(tempdir(), "resrepo_example")
  if (dir.exists(example_dir)) {
    fs::dir_delete(example_dir)
  }
  dir.create(example_dir, showWarnings = FALSE)

  # create a subdirectory of example_dir
  sub_dir <- file.path(example_dir, "subdir")
  dir.create(sub_dir, showWarnings = FALSE)

  example_repo <- git2r::init(sub_dir, branch = "main")
  git2r::config(example_repo,
    user.name = "Test",
    user.email = "test@example.org"
  )
  # set our working directory in the git repository
  withr::local_dir(as.character(sub_dir))

  init_resrepo()

  external_data_storage <- file.path(tempdir(), "external_data_storage")
  if (dir.exists(external_data_storage)) {
    fs::dir_delete(external_data_storage)
  }
  dir.create(external_data_storage)

  version_setup(quiet = TRUE, resources_path = external_data_storage)


  file.copy(
    from = system.file("vignette_example/s01_download_penguins.Rmd",
      package = "resrepo"
    ),
    to = path_resrepo("/code/s01_download_penguins.Rmd"),
    overwrite = TRUE
  )
  file.copy(
    from = system.file("vignette_example/s02_merge_clean.Rmd",
      package = "resrepo"
    ),
    to = path_resrepo("/code/s02_merge_clean.Rmd"),
    overwrite = TRUE
  )
  file.copy(
    from = system.file("vignette_example/s03_pca.Rmd", package = "resrepo"),
    to = path_resrepo("/code/s03_pca.Rmd"),
    overwrite = TRUE
  )

  file.copy(
    from = system.file("vignette_example/tux_measurements.csv",
      package = "resrepo"
    ),
    to = path_resrepo("/data/raw/original/tux_measurements.csv"),
    overwrite = TRUE
  )

  # silence knitr
  suppressMessages(
    capture.output(
      knit_to_results(path_resrepo("/code/s01_download_penguins.Rmd"))
    )
  )
  # silence knitr
  suppressMessages(
    capture.output(knit_to_results(path_resrepo("/code/s02_merge_clean.Rmd")))
  )
  # silence knitr
  suppressMessages(
    capture.output(knit_to_results(path_resrepo("/code/s03_pca.Rmd")))
  )


  # write a text file to ../data/raw/original to check the link works
  write.csv("blah", path_resrepo("/data/raw/original/my_new_file1.csv"),
    row.names = FALSE
  )
  # read csv from the versions folder to check link worked
  df_check <- read.csv(path_resrepo("data/raw/original/my_new_file1.csv"))
  expect_equal(as.character(df_check), "blah")

  # create another external data storage folder
  new_external_data_storage <- file.path(tempdir(), "new_external_data_storage")

  # create new data directory where we want to move our data
  dir.create(new_external_data_storage, showWarnings = FALSE)

  # move versions folder to new_data_dir
  file.rename(
    from = "../../external_data_storage/versions",
    to = file.path(new_external_data_storage, "versions")
  )

  list.files(file.path(new_external_data_storage, "versions"))
  list.files("../../external_data_storage/versions")

  # relink the version
  version_relink(quiet = TRUE, resources_path = new_external_data_storage)

  # write a text file to ../data/raw/original to check the link works
  write.csv("blah", path_resrepo("/data/raw/original/my_new_file1.csv"),
    row.names = FALSE
  )

  # read csv from the versions folder to check link worked
  df_check <- read.csv(path_resrepo("data/raw/original/my_new_file1.csv"))

  expect_equal(as.character(df_check), "blah")
})


# TODO handle case where user may try to move one subfolder of versions - give
# an informative error and note in the vignette that all versions must be in the
# same place!

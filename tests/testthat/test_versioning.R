# this file tests several functions related to versioning
test_that("versioning", {
  ############
  # start setting up a temp dir for the git repository
  example_dir <- file.path(tempdir(), "resrepo_example")
  unlink(example_dir, recursive = TRUE)
  dir.create(example_dir, showWarnings = FALSE)
  example_repo <- git2r::init(example_dir, branch = "main")
  git2r::config(example_repo,
    user.name = "Test",
    user.email = "test@example.org"
  )
  vignette_dir <- getwd()
  # set our working directory in the git repository
  setwd(example_dir)
  ############
  # initialise the repository and add the relevant files
  # TODO this section is very noisy, we should suppress the output
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
    from = system.file("vignette_example/s03_pca.Rmd",
      package = "resrepo"
    ),
    to = path_resrepo("/code/s03_pca.Rmd"),
    overwrite = TRUE
  )
  knit_to_results(path_resrepo("/code/s03_pca.Rmd"))
  git2r::add(path = ".")
  git2r::commit(message = "Save plot", all = TRUE)
  # check that we are on main and there is nothing to commit
  expect_true(git2r::is_head(git2r::branches()$main))
  # check that all elements of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())

  ############
  # set up versioning
  expect_true(version_setup(quiet = TRUE))
  # test that the link to data raw is working correctly
  expect_true(setequal(
    list.files(path_resrepo("/data/raw")),
    c("original", "README.md", "s01_download_penguins")
  ))
  # check that we are still in main with nothing to commit
  expect_true(git2r::is_head(git2r::branches()$main))
  # check that all element of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())

  #########
  # fail to add another version if we have changes to commit
  write.csv("blah", path_resrepo("/code/random_code.R"))
  expect_error(
    version_add(
      new_version = "new_filtering",
      description = "Filtering out some data",
      quiet = TRUE
    ),
    "You have uncommitted changes;"
  )
  file.remove(path_resrepo("/code/random_code.R"))

  ############
  # add another version
  expect_true(version_add(
    new_version = "new_filtering",
    description = "Filtering out some data", quiet = TRUE
  ))
  # check that we are on a new branch and there is nothing to commit
  expect_true(git2r::is_head(git2r::branches()$new_filtering))
  # check that allelement of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())
  # check that we created the correct resources and that the links are correct
  expect_true(dir.exists(path_resrepo("version_resources/new_filtering/raw")))
  expect_true(
    dir.exists(
      path_resrepo("version_resources/new_filtering/intermediate")
    )
  )

  # check that the links point to the right places
  write.csv("blah", path_resrepo("/data/raw/original/my_new_file1.csv"))
  expect_true(
    file.exists(
      path_resrepo(
        "/version_resources/new_filtering/raw/original/my_new_file1.csv"
      )
    )
  )
  # the repo should still have a clean working directory
  expect_true(git_is_clean())
  ##########
  # move back to main and check that we use the correct version (initial)
  # note that we need to use system2 to run git commands as
  # git2r::checkout does not trigger hooks
  system2("git", args = c("checkout main"))
  expect_true(git2r::is_head(git2r::branches()$main))
  expect_true(grep("initial", fs::link_path("./data/raw")) == 1)
  #########
  # merge new_filtering into main
  system2("git", args = c("merge new_filtering"))
  # we are still in main
  expect_true(git2r::is_head(git2r::branches()$main))
  # but the data version is new_filtering as a consequence of the merge
  expect_true(grep("new_filtering", fs::link_path("./data/raw")) == 1)
  #########
  # change data version in main back to initial
  version_switch("initial")
  expect_true(grep("initial", fs::link_path("./data/raw")) == 1)
})

# this file tests several functions related to versioning
test_that("versioning with resources_path argument", {
  ############
  # start setting up a temp dir for the git repository
  example_dir <- file.path(tempdir(), "resrepo_example")
  unlink(example_dir, recursive = TRUE)
  dir.create(example_dir, showWarnings = FALSE)
  setwd(example_dir)
  git2r::init(example_dir, branch = "main")
  init_resrepo()
  # check that we are on main and there is nothing to commit
  expect_true(git2r::is_head(git2r::branches()$main))
  # check that all elements of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())

  ############
  # set up versioning
  external_data_storage <- tempfile()
  dir.create(external_data_storage)
  # expect_true(version_setup(resources_path = external_data_storage, quiet = TRUE))
  # copy in some data
  # file.copy(
  #   from = system.file("vignette_example/tux_measurements.csv",
  #                      package = "resrepo"
  #   ),
  #   to = path_resrepo("/data/raw/original/tux_measurements.csv"),
  #   overwrite = TRUE
  # )
  # # test that the link to data raw is working correctly
  # expect_true(setequal(
  #   list.files(path_resrepo("/data/raw")),
  #   c("original","README.md")
  # ))
  # # check that we are still in main with nothing to commit
  # expect_true(git2r::is_head(git2r::branches()$main))
  # # check that all element of git status are empty (i.e. we have a
  # # cleaned working directory)
  # expect_true(git_is_clean())
  #
  # ############
  # # add another version
  # expect_true(version_add(
  #   new_version = "new_filtering",
  #   description = "Filtering out some data", quiet = TRUE
  # ))
  # # check that we are on a new branch and there is nothing to commit
  # expect_true(git2r::is_head(git2r::branches()$new_filtering))
  # # check that allelement of git status are empty (i.e. we have a
  # # cleaned working directory)
  # expect_true(git_is_clean())
  # # check that we created the correct resources and that the links are correct
  # expect_true(dir.exists(path_resrepo("version_resources/new_filtering/raw")))
  # expect_true(
  #   dir.exists(
  #     path_resrepo("version_resources/new_filtering/intermediate")
  #   )
  # )
  #
  # # check that the links point to the right places
  # write.csv("blah", path_resrepo("/data/raw/original/my_new_file1.csv"))
  # expect_true(
  #   file.exists(
  #     path_resrepo(
  #       "/version_resources/new_filtering/raw/original/my_new_file1.csv"
  #     )
  #   )
  # )
  # # the repo should still have a clean working directory
  # expect_true(git_is_clean())
  #
  #

})

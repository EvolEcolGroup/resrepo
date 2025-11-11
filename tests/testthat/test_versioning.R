# this file tests several functions related to versioning
test_that("versioning", {
  ############
  # start setting up a temp dir for the git repository
  example_dir <- file.path(tempdir(), "resrepo_example")
  # wipe the directory in case it has been left behind from previous tests
  unlink(example_dir, recursive = TRUE)
  # create the directory for this test
  expect_true(dir.create(example_dir, showWarnings = FALSE))
  example_repo <- git2r::init(example_dir, branch = "main")
  git2r::config(example_repo,
    user.name = "Test",
    user.email = "test@example.org"
  )
  # set our working directory in the git repository
  setwd(example_dir)
  ############
  # initialise the repository and add the relevant files
  init_resrepo()
  expect_true(file.copy(
    from = system.file("vignette_example/tux_measurements.csv",
      package = "resrepo"
    ),
    to = path_resrepo("/data/raw/original/tux_measurements.csv"),
    overwrite = TRUE
  ))
  expect_true(file.copy(
    from = system.file("vignette_example/s01_download_penguins.Rmd",
      package = "resrepo"
    ),
    to = path_resrepo("/code/s01_download_penguins.Rmd"),
    overwrite = TRUE
  ))
  # silence knitr
  suppressMessages(
    capture.output(
      knit_to_results(path_resrepo("/code/s01_download_penguins.Rmd"))
    )
  )
  expect_true(file.copy(
    from = system.file("vignette_example/s02_merge_clean.Rmd",
      package = "resrepo"
    ),
    to = path_resrepo("/code/s02_merge_clean.Rmd"),
    overwrite = TRUE
  ))
  suppressMessages(
    capture.output(
      knit_to_results(path_resrepo("/code/s02_merge_clean.Rmd"))
    )
  )
  expect_true(file.copy(
    from = system.file("vignette_example/s03_pca.Rmd",
      package = "resrepo"
    ),
    to = path_resrepo("/code/s03_pca.Rmd"),
    overwrite = TRUE
  ))
  suppressMessages(
    capture.output(
      knit_to_results(path_resrepo("/code/s03_pca.Rmd"))
    )
  )
  git2r::add(path = ".")
  suppressMessages(
    capture.output(
      git2r::commit(message = "Save plot", all = TRUE)
    )
  )
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
      intermediate_new_version = "new_filtering",
      intermediate_description = "Filtering out some data",
      quiet = TRUE
    ),
    "You have uncommitted changes;"
  )
  file.remove(path_resrepo("/code/random_code.R"))

  ############
  # add another version
  expect_true(version_add(
    intermediate_new_version = "new_filtering",
    intermediate_description = "Filtering out some data", quiet = TRUE
  ))
  # check that we are on a new branch and there is nothing to commit
  expect_true(git2r::is_head(git2r::branches()$new_filtering))
  # copy the new penguin filtering script
  file.copy(
    from = system.file("vignette_example/new_filtering/s02_merge_clean.Rmd",
      package = "resrepo"
    ),
    to = path_resrepo("code/s02_merge_clean.Rmd"),
    overwrite = TRUE
  )
  # knit the new script
  suppressMessages(
    capture.output(
      knit_to_results(path_resrepo("code/s02_merge_clean.Rmd"))
    )
  )
  # commit changes
  suppressMessages(
    capture.output(
      git2r::commit(message = "Remove penguins", all = TRUE)
    )
  )
  # check that allelement of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())
  # check that we created the correct resources and that the links are correct
  expect_true(dir.exists(path_resrepo("versions/new_filtering/intermediate")))
  expect_false(
    dir.exists(
      path_resrepo("versions/new_filtering/raw")
    )
  )

  # check that the links point to the right places
  write.csv("blah", path_resrepo("/data/intermediate/my_new_file1.csv"))
  expect_true(
    file.exists(
      path_resrepo(
        "/versions/new_filtering/intermediate/my_new_file1.csv"
      )
    )
  )
  # the repo should still have a clean working directory
  expect_true(git_is_clean())
  ##########
  # move back to main and check that we use the correct version (initial)
  # note that we need to use system2 to run git commands as
  # git2r::checkout does not trigger hooks
  # TODO this is noisy, we should suppress the output

  suppressMessages(
    capture.output(
      system2("git", args = c("checkout main"))
    )
  )
  expect_true(git2r::is_head(git2r::branches()$main))
  expect_true(grep("starting", fs::link_path("./data/raw")) == 1)

  cat(fs::link_path("./data/intermediate"))

  expect_true(grep("initial", fs::link_path("./data/intermediate")) == 1)

  # Check that data/intermediate now points to the unfiltered penguin data
  penguins_initial <- read.csv(path_resrepo(
    "data/intermediate/s02_merge_clean/penguins_na_omit.csv"
  ))
  penguins_new_filtering <- read.csv(
    "versions/new_filtering/intermediate/s02_merge_clean/penguins_na_omit.csv"
  )
  expect_true(nrow(penguins_initial) > nrow(penguins_new_filtering))
  #########
  # merge new_filtering into main
  suppressMessages(
    capture.output(
      git_res <- system2("git", args = c("merge new_filtering"))
    )
  )
  # we are still in main
  expect_true(git2r::is_head(git2r::branches()$main))
  # but the data version is new_filtering as a consequence of the merge
  expect_true(grep("new_filtering", fs::link_path("./data/intermediate")) == 1)
  penguins <- read.csv(path_resrepo(
    "data/intermediate/s02_merge_clean/penguins_na_omit.csv"
  ))
  expect_true(nrow(penguins) == nrow(penguins_new_filtering))
})

# this file tests several functions related to versioning
test_that("versioning with resources_path argument", {
  setwd(tempdir())
  ############
  # start setting up a temp dir for the git repository
  example_dir <- file.path(tempdir(), "resrepo_example")
  # wipe the directory in case it has been left behind from previous tests
  unlink(example_dir, recursive = TRUE)
  # create the directory for this test
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
  setwd(sub_dir)
  init_resrepo()
  # check that we are on main and there is nothing to commit
  expect_true(git2r::is_head(git2r::branches()$main))
  # check that all elements of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())

  ############
  # set up versioning
  external_data_storage <- file.path(tempdir(), "external_data_storage")
  # erase everything from the data storage folder
  unlink(external_data_storage, recursive = TRUE)
  # create the folder for data storage
  dir.create(external_data_storage, showWarnings = FALSE)
  expect_true(version_setup(
    resources_path = external_data_storage,
    quiet = TRUE
  ))
  # copy in some data
  file.copy(
    from = system.file("vignette_example/tux_measurements.csv",
      package = "resrepo"
    ),
    to = path_resrepo("/data/raw/original/tux_measurements.csv"),
    overwrite = TRUE
  )
  # test that the link to data raw is working correctly
  expect_true(setequal(
    list.files(path_resrepo("/data/raw")),
    c("original", "README.md")
  ))
  # check that we are still in main with nothing to commit
  expect_true(git2r::is_head(git2r::branches()$main))
  # check that all element of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())

  ############
  # add another version
  expect_true(version_add(
    intermediate_new_version = "new_filtering",
    intermediate_description = "Filtering out some data", quiet = TRUE
  ))
  # check that we are on a new branch and there is nothing to commit
  expect_true(git2r::is_head(git2r::branches()$new_filtering))
  # check that allelement of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())
  # check that we created the correct resources and that the links are correct
  expect_true(dir.exists(path_resrepo("versions/new_filtering/intermediate")))
  expect_true(
    dir.exists(
      path_resrepo("versions/new_filtering/intermediate")
    )
  )

  # check that the links point to the right places
  # raw should still be in the starting version
  write.csv("blah", path_resrepo("/data/raw/original/my_new_file1.csv"))
  expect_true(
    file.exists(
      path_resrepo(
        "/versions/starting/raw/original/my_new_file1.csv"
      )
    )
  )
  # the repo should still have a clean working directory
  expect_true(git_is_clean())
})

test_that(paste0(
  "check that you cannot add a new data raw version ",
  "without a new data intermediate version"
), {
  setwd(tempdir())
  ############
  # start setting up a temp dir for the git repository
  example_dir <- file.path(tempdir(), "resrepo_example")
  # wipe the directory in case it has been left behind from previous tests
  unlink(example_dir, recursive = TRUE)
  # create the directory for this test
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
  setwd(sub_dir)
  init_resrepo()
  # check that we are on main and there is nothing to commit
  expect_true(git2r::is_head(git2r::branches()$main))
  # check that all elements of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())

  expect_true(version_setup(quiet = TRUE))

  # Try adding a version of data raw without adding a new version of
  # data intermediate
  expect_error(version_add(
    raw_new_version = "new_raw_version",
    raw_description = "A new version of raw data",
    quiet = TRUE
  ), "You must provide a name for the new intermediate version")
})


test_that("resources_path cannot be set to git root", {
  setwd(tempdir())
  ############
  # start setting up a temp dir for the git repository
  example_dir <- file.path(tempdir(), "resrepo_example")
  # wipe the directory in case it has been left behind from previous tests
  unlink(example_dir, recursive = TRUE)
  # create the directory for this test
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
  setwd(sub_dir)
  init_resrepo()
  # check that we are on main and there is nothing to commit
  expect_true(git2r::is_head(git2r::branches()$main))
  # check that all elements of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())
  ######## Currently, this test does not work, see version_setup ########

  # find git root
  git_root <- find_git_root()
  expect_error(
    version_setup(git_root, quiet = TRUE),
    "resources_path cannot be the root directory of the repository"
  )
  root_full_path <- getwd()
  expect_error(
    version_setup(root_full_path, quiet = TRUE),
    "resources_path cannot be the root directory of the repository"
  )
})

test_that("clone a versioned repo", {
  directory_penguins <- file.path(tempdir(), "resrepo_penguins")
  if (!dir.exists(directory_penguins)) dir.create(directory_penguins)

  # clone the penguin repository (public)
  git2r::clone("https://github.com/EvolEcolGroup/resrepo_penguins",
    local_path = directory_penguins,
    branch = "test_intermediate_description4",
    progress = FALSE
  )

  setwd(directory_penguins)
  expect_true(read.table("data/version_meta/intermediate_in_use.meta") ==
    "test_intermediate_description4") # nolint

  # create new external folder for data
  external_data_storage_new <- file.path(tempdir(), "external_data_storage_new")
  dir.create(external_data_storage_new)

  intermediate_path <- file.path(
    tempdir(),
    "external_data_storage_new/initial/intermediate"
  )
  raw_path <- file.path(tempdir(), "external_data_storage_new/starting/raw")
  dir.create(intermediate_path, recursive = TRUE)
  dir.create(raw_path, recursive = TRUE)

  file.copy(
    from = system.file("vignette_example/tux_measurements.csv",
      package = "resrepo"
    ),
    to = raw_path,
    overwrite = TRUE
  )

  expect_true(version_setup(
    quiet = TRUE,
    resources_path = external_data_storage_new
  ))

  # If we have cloned from a branch and then set up versioning,
  # can we merge back into
  # main
  write.csv("blah", path_resrepo("/data/intermediate/my_new_file1.csv"))
  expect_true(git_is_clean())

  # merge back into main
  suppressMessages(
    capture.output(
      system2("git", args = c("checkout main"))
    )
  )
  expect_true(git2r::is_head(git2r::branches()$main))
  # check we are back to the initial version
  expect_true(grep("initial", fs::link_path("./data/intermediate")) == 1)
})

# @TODO find ways to break data versioning (cases when you clone the repository
# but don't have the stuff in the right path)

# @TODO write a test to check when you create versioned repo with version_setup
# and then switch branches, the data still points to the right place

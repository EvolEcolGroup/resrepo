test_that("path_is_data_dir works correctly", {
  path <- "/data/raw/default"
  expect_true(path_is_data_dir(path))
  path <- "data/raw/default"
  expect_error(path_is_data_dir(path), path)
  path <- "/data/blah/default"
  expect_error(path_is_data_dir(path), path)
})
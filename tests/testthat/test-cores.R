# tests/testthat/test-cores.R
library(testthat)

test_that("the tests run with at most 2 cores", {
  skip_on_cran()
  expect_identical(Sys.getenv("OMP_THREAD_LIMIT"), "2")
  expect_lte(data.table::getDTthreads(), 2L)
})
